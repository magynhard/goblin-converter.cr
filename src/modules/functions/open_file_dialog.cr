require "gettext"

module GoblinApp
  module OpenFileDialog
    extend self

    def show(parent, title : String, action : Gtk::FileChooserAction, file : String? = nil, &block : String ->)
      dialog = Gtk::FileDialog.new
      dialog.title = title

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
  end
end
