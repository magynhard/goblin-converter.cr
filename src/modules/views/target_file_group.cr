module GoblinApp
  class MainWindow
    private def create_target_file_group(box)
      group = Adw::PreferencesGroup.new
      group.title = GoblinApp.translate("Target")

      save_button = Gtk::Button.new
      save_button.icon_name = "document-save-symbolic"
      save_button.valign = :center
      save_button.halign = :center

      edit_button = Gtk::Button.new
      edit_button.icon_name = "document-edit-symbolic"
      edit_button.valign = :center
      edit_button.halign = :center
      edit_button.margin_end = 10

      button_box = Gtk::Box.new(:horizontal, 0)
      button_box.append(edit_button)
      button_box.append(save_button)
      button_box.append(folder_menu_button("app.open-target-folder", "open-target-folder") do
        open_containing_folder(@form_data.target_path)
      end)

      @output_entry_row = Adw::ActionRow.new
      @output_entry_row.not_nil!.title = GoblinApp.translate("Select target file")
      @output_entry_row.not_nil!.subtitle = "-"
      @output_entry_row.not_nil!.activatable = true
      @output_entry_row.not_nil!.add_suffix(button_box)

      @output_entry_row.not_nil!.activated_signal.connect do
        on_target_row_clicked
      end

      save_button.clicked_signal.connect do
        on_target_row_clicked
      end

      edit_button.clicked_signal.connect do
        on_target_row_edit_clicked
      end

      # Drag & Drop support
      drop_target = Gtk::DropTarget.new(Gdk::FileList.g_type, Gdk::DragAction::Copy)
      drop_target.drop_signal.connect do |value, x, y|
        if path = dropped_file_path(value)
          @form_data = @form_data.copy_with(target_path: path)
          @output_entry_row.not_nil!.subtitle = path
          GoblinApp.log("Target changed (drag & drop): #{path}")
          true
        else
          GoblinApp.log("Drop ignored: no local file")
          false
        end
      end

      @output_entry_row.not_nil!.add_controller(drop_target)

      group.add(@output_entry_row.not_nil!)
      box.append(group)
    end

    private def on_target_row_clicked
      OpenFileDialog.show(@window, GoblinApp.translate("Select target file"), Gtk::FileChooserAction::Save, @form_data.target_path) do |file|
        @form_data = @form_data.copy_with(target_path: file)
        @output_entry_row.not_nil!.subtitle = file
        GoblinApp.log("Target changed (file dialog): #{file}")
      end
    end

    private def on_target_row_edit_clicked
      dialog = Adw::AlertDialog.new(GoblinApp.translate("Edit path"), "")

      entry = Gtk::Entry.new
      entry.text = @form_data.target_path || ""
      entry.width_chars = 60
      dialog.extra_child = entry

      dialog.add_response("cancel", GoblinApp.translate("_Cancel"))
      dialog.add_response("apply", GoblinApp.translate("_Apply"))
      dialog.set_response_appearance("apply", Adw::ResponseAppearance::Suggested)
      dialog.default_response = "apply"
      dialog.close_response = "cancel"

      dialog.response_signal.connect do |response|
        if response == "apply"
          @form_data = @form_data.copy_with(target_path: entry.text)
          @output_entry_row.not_nil!.subtitle = entry.text
          GoblinApp.log("Target changed (manual edit): #{entry.text}")
        end
        dialog.force_close
      end

      dialog.present(@window)
    end
  end
end
