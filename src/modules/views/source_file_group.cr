module GoblinApp
  class MainWindow
    private def create_source_file_group(box)
      group = Adw::PreferencesGroup.new
      group.title = GoblinApp.translate("Source")

      source_button = Gtk::Button.new
      source_button.icon_name = "document-open-symbolic"
      source_button.valign = :center
      source_button.halign = :center

      button_box = Gtk::Box.new(:horizontal, 0)
      button_box.append(source_button)

      @source_file_row = Adw::ActionRow.new
      @source_file_row.not_nil!.title = GoblinApp.translate("Select Source File")
      @source_file_row.not_nil!.subtitle = "-"
      @source_file_row.not_nil!.activatable = true
      @source_file_row.not_nil!.add_suffix(button_box)

      @source_file_row.not_nil!.activated_signal.connect do
        on_source_row_clicked
      end

      source_button.clicked_signal.connect do
        on_source_row_clicked
      end

      # Drag & Drop support
      drop_target = Gtk::DropTarget.new(Gdk::FileList.g_type, Gdk::DragAction::Copy)
      drop_target.drop_signal.connect do |value, x, y|
        if path = dropped_file_path(value)
          @form_data = @form_data.copy_with(source_path: path)
          @source_file_row.not_nil!.subtitle = path
          GoblinApp.log("Source changed (drag & drop): #{path}")
          auto_target = path.gsub(/\.([a-zA-Z]{3,4})$/, "_converted.\\1")
          @form_data = @form_data.copy_with(target_path: auto_target)
          @output_entry_row.not_nil!.subtitle = auto_target
          GoblinApp.log("Target auto-set: #{auto_target}")
          true
        else
          GoblinApp.log("Drop ignored: no local file")
          false
        end
      end

      @source_file_row.not_nil!.add_controller(drop_target)

      group.add(@source_file_row.not_nil!)
      box.append(group)
    end

    private def on_source_row_clicked
      OpenFileDialog.show(@window, GoblinApp.translate("Select Source File"), Gtk::FileChooserAction::Open) do |file|
        @form_data = @form_data.copy_with(source_path: file)
        @source_file_row.not_nil!.subtitle = file
        GoblinApp.log("Source changed (file dialog): #{file}")
        auto_target = file.gsub(/\.([a-zA-Z]{3,4})$/, "_converted.\\1")
        @form_data = @form_data.copy_with(target_path: auto_target)
        @output_entry_row.not_nil!.subtitle = auto_target
        GoblinApp.log("Target auto-set: #{auto_target}")
      end
    end

    # Extracts the first local file path from a drop value. The drop
    # signal hands over a GObject::Value (never a Gdk::FileList
    # directly), so the boxed list must be unwrapped first. Returns nil
    # for unexpected types, empty lists, or non-local files.
    private def dropped_file_path(value : GObject::Value) : String?
      return nil unless value.g_type == Gdk::FileList.g_type
      boxed = LibGObject.g_value_get_boxed(value.to_unsafe)
      return nil if boxed.null?
      file_list = Gdk::FileList.new(boxed, GICrystal::Transfer::None)
      file_list.files.each do |file|
        if local_path = file.path
          return local_path.to_s
        end
      end
      nil
    end
  end
end
