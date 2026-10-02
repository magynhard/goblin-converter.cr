module GoblinApp
  class MainWindow
    private def create_convert_button_group(box)
      list_box = Gtk::ListBox.new
      list_box.selection_mode = :none
      list_box.add_css_class("boxed-list-separate")

      convert_button = Adw::ButtonRow.new
      convert_button.title = GoblinApp.translate("Convert")
      convert_button.activatable = true
      convert_button.add_css_class("suggested-action")
      convert_button.add_css_class("boxed-list-separate")

      convert_button.activated_signal.connect do
        on_convert_clicked
      end

      list_box.append(convert_button)
      box.append(list_box)
    end

    private def on_convert_clicked
      source_file = @form_data.source_path
      output_file = @form_data.target_path

      if source_file.nil? || source_file.empty? || output_file.nil? || output_file.empty?
        GoblinApp.log("Conversion aborted: source or target file missing")
        Dialogs.show_custom_dialog(@window, text: GoblinApp.translate("Please select both source and output files."), message_type: :error)
        return
      end

      if File.exists?(output_file)
        GoblinApp.log("Target already exists, asking for overwrite: #{output_file}")
        Dialogs.show_overwrite_dialog(@window) do |overwrite|
          if overwrite
            GoblinApp.log("Overwrite confirmed: #{output_file}")
            start_conversion(source_file, output_file)
          else
            GoblinApp.log("Conversion cancelled (target exists): #{output_file}")
          end
        end
        return
      end

      start_conversion(source_file, output_file)
    end

    # Runs magick via Gio::SubprocessLauncher (argv, no shell) with
    # stdout/stderr redirected to tempfiles, then polls completion with
    # a raw waitpid(WNOHANG) from a GLib.timeout on the main loop.
    # Never use Crystal Thread/spawn/Channel or Process (with any
    # redirects) for subprocesses here: fibers don't run while GTK
    # blocks the main thread, and Process waiting hangs on worker
    # threads (proven via headless harness). waitpid on the main thread
    # never blocks thanks to WNOHANG.
    private def start_conversion(source_file : String, output_file : String)
      options = @form_data.options
      argv = GoblinApp.magick_args(source_file, output_file, options)
      GoblinApp.log("Running: #{GoblinApp.magick_command(source_file, output_file, options)}")

      progress = Dialogs.show_progress_dialog(@window)

      out_log = File.tempfile("goblin-converter-stdout", ".log")
      err_log = File.tempfile("goblin-converter-stderr", ".log")

      proc = begin
        launcher = Gio::SubprocessLauncher.new(Gio::SubprocessFlags::SearchPathFromEnvp)
        {% unless flag?(:win32) %}
          # File fds are C ints only on Unix; on Windows the child
          # inherits stdio instead (magick output then goes to console).
          launcher.take_stdout_fd(out_log.fd)
          launcher.take_stderr_fd(err_log.fd)
          null_in = File.open(File::NULL, "r")
          launcher.take_stdin_fd(null_in.fd)
        {% end %}
        subprocess = launcher.spawnv(argv)
        {% unless flag?(:win32) %}
          null_in.close
        {% end %}
        subprocess
      rescue ex
        GoblinApp.log("Failed to launch magick: #{ex.message}")
        progress.force_close
        read_and_cleanup(out_log)
        read_and_cleanup(err_log)
        Dialogs.show_custom_dialog(@window, text: GoblinApp.translate("An error occurred while conversion!"), message_type: :error)
        return
      end

      {% if flag?(:win32) %}
        # Windows has no waitpid: let GLib reap the child and report via
        # callback (needs subprocess_patch for the fixed binding).
        GoblinApp.log("magick launched, waiting for completion...")
        proc.wait_check_async(nil) do |_source, result|
          begin
            proc.wait_check_finish(result)
            finish_conversion(true, "exit 0",
              source_file, output_file, progress, out_log, err_log)
          rescue ex
            finish_conversion(false, ex.message || "unknown error",
              source_file, output_file, progress, out_log, err_log)
          end
        end
      {% else %}
        pid = proc.identifier.try(&.to_i?)
        if pid.nil?
          GoblinApp.log("Failed to launch magick: could not determine child pid")
          progress.force_close
          read_and_cleanup(out_log)
          read_and_cleanup(err_log)
          Dialogs.show_custom_dialog(@window, text: GoblinApp.translate("An error occurred while conversion!"), message_type: :error)
          return
        end

        GoblinApp.log("magick launched (pid #{pid}), waiting for completion...")
        GLib.timeout(250.milliseconds) do
          ret = LibC.waitpid(pid, out status, LibC::WNOHANG)
          if ret == 0
            true
          elsif ret == pid
            # We reaped the child ourselves (beat GLib's child watch).
            finish_conversion(GoblinApp.exited_ok?(status), "exit #{GoblinApp.exit_code(status)}",
              source_file, output_file, progress, out_log, err_log)
            false
          elsif Errno.value == Errno::EINTR
            # Transient interruption, child state unknown: keep polling.
            true
          else
            # ECHILD: GLib's child watch already reaped the process, ask it.
            ok = proc.successful
            info = ok ? "exit #{GoblinApp.exit_code(proc.exit_status)}" : "raw status #{proc.exit_status}"
            finish_conversion(ok, info, source_file, output_file, progress, out_log, err_log)
            false
          end
        end
      {% end %}
    end

    private def finish_conversion(success : Bool, status_info : String, source_file : String, output_file : String, progress : Adw::AlertDialog, out_log : File, err_log : File) : Nil
      stdout_text = read_and_cleanup(out_log)
      stderr_text = read_and_cleanup(err_log)
      progress.force_close
      if success
        GoblinApp.log("Conversion succeeded (#{status_info}): #{source_file} -> #{output_file}")
        GoblinApp.log("magick stdout:\n#{stdout_text}") unless stdout_text.empty?
        GoblinApp.log("magick stderr:\n#{stderr_text}") unless stderr_text.empty?
        Dialogs.show_custom_dialog(@window, text: GoblinApp.translate("Conversion Complete!"), message_type: :info)
      else
        GoblinApp.log("Conversion failed (#{status_info}): #{source_file} -> #{output_file}")
        GoblinApp.log("magick stdout:\n#{stdout_text}") unless stdout_text.empty?
        GoblinApp.log("magick stderr:\n#{stderr_text}") unless stderr_text.empty?
        Dialogs.show_custom_dialog(@window, text: GoblinApp.translate("An error occurred while conversion!"), message_type: :error)
      end
    end

    # Reads a tempfile's content, then closes and deletes it.
    private def read_and_cleanup(log : File) : String
      text = begin
        log.rewind
        log.gets_to_end
      rescue
        ""
      end
      begin
        path = log.path
        log.close
        File.delete(path)
      rescue
      end
      text
    end
  end
end
