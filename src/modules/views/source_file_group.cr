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
        if value.is_a?(Gdk::FileList)
          files = value.files
          if files.size > 0
            path = files.first.path.to_s
            @form_data = @form_data.copy_with(source_path: path)
            @source_file_row.not_nil!.subtitle = path
            auto_target = path.gsub(/\.([a-zA-Z]{3,4})$/, "_converted.\\1")
            @form_data = @form_data.copy_with(target_path: auto_target)
            @output_entry_row.not_nil!.subtitle = auto_target
          end
        end
        true
      end

      @source_file_row.not_nil!.add_controller(drop_target)

      group.add(@source_file_row.not_nil!)
      box.append(group)
    end

    private def on_source_row_clicked
      OpenFileDialog.show(@window, GoblinApp.translate("Select Source File"), Gtk::FileChooserAction::Open) do |file|
        @form_data = @form_data.copy_with(source_path: file)
        @source_file_row.not_nil!.subtitle = file
        auto_target = file.gsub(/\.([a-zA-Z]{3,4})$/, "_converted.\\1")
        @form_data = @form_data.copy_with(target_path: auto_target)
        @output_entry_row.not_nil!.subtitle = auto_target
      end
    end
  end
end
