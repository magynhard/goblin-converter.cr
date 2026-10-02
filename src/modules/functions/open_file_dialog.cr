require "gettext"

module GoblinApp
  module OpenFileDialog
    extend self

    def show(parent, title : String, action : Gtk::FileChooserAction, file : String? = nil, &block : String ->)
      dialog = Gtk::FileDialog.new
      dialog.title = title
      preset_initial_location(dialog, action, file)

      callback = block

      if action == Gtk::FileChooserAction::Save
        dialog.save(parent, nil) do |obj, result|
          begin
            gfile = dialog.save_finish(result)
            callback.call(gfile.path.not_nil!.to_s) if gfile
          rescue e
            STDERR.puts("Error: #{e.message}")
          end
        end
      else
        dialog.open(parent, nil) do |obj, result|
          begin
            gfile = dialog.open_finish(result)
            callback.call(gfile.path.not_nil!.to_s) if gfile
          rescue e
            STDERR.puts("Error: #{e.message}")
          end
        end
      end
    end

    private def preset_initial_location(dialog : Gtk::FileDialog, action : Gtk::FileChooserAction, file : String?) : Nil
      return if file.nil? || file.empty?
      if action == Gtk::FileChooserAction::Save
        # Prefill folder + filename (target may not exist yet).
        parent = File.dirname(file)
        dialog.initial_folder = Gio::File.new_for_path(parent) if Dir.exists?(parent)
        dialog.initial_name = File.basename(file)
      elsif File.exists?(file)
        dialog.initial_file = Gio::File.new_for_path(file)
      end
    end
  end
end
