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
        Dialogs.show_custom_dialog(@window, text: GoblinApp.translate("Please select both source and output files."), message_type: :error)
        return
      end

      if File.exists?(output_file)
        selection = Dialogs.show_overwrite_dialog(@window)
        return if selection != "overwrite"
      end

      options = @form_data.options
      mode = options.mode
      density = options.resolution
      threshold = options.threshold
      quality = options.quality

      mode_parameter = case mode
                       when "monochrome"
                         "-threshold #{threshold}% -monochrome -compress Fax"
                       when "grayscale"
                         "-colorspace Gray -compress Zip"
                       when "grayscale_quality"
                         "-colorspace Gray -compress JPEG -quality #{quality}"
                       when "color"
                         "-compress JPEG -quality #{quality}"
                       else
                         "-threshold #{threshold}% -monochrome -compress Fax"
                       end

      strip_flag = options.strip_metadata ? " -strip" : ""
      command = "magick -density #{density} #{Process.quote(source_file)} #{mode_parameter}#{strip_flag} #{Process.quote(output_file)}"

      info = Dialogs.show_custom_dialog(@window, text: GoblinApp.translate("Converting..."), message_type: :info)

      channel = Channel(Bool).new

      spawn do
        result = Process.run(command, shell: true, error: Process::Redirect::Pipe, output: Process::Redirect::Pipe)
        channel.send(result.success?)
      end

      spawn do
        success = channel.receive
        info.force_close
        if success
          Dialogs.show_custom_dialog(@window, text: GoblinApp.translate("Conversion Complete!"), message_type: :info)
        else
          Dialogs.show_custom_dialog(@window, text: GoblinApp.translate("An error occurred while conversion!"), message_type: :error)
        end
      end
    end
  end
end
