require "../prerequisites"
require "../views/main_window"

module GoblinApp
  module Dialogs
    extend self

    def show_custom_dialog(parent, text : String, title : String = "Info", message_type : Symbol = :default)
      dialog_title = message_type == :info ? "Information" : "Error"
      dialog = Adw::AlertDialog.new(dialog_title, text)

      label = Gtk::Label.new(text)
      label.margin_top = 10
      label.margin_bottom = 10

      ok_button = Gtk::Button.new(label: "OK")
      ok_button.clicked_signal.connect do
        dialog.force_close
      end

      vbox = Gtk::Box.new(:vertical, 0)
      vbox.margin_top = 20
      vbox.margin_bottom = 20
      vbox.margin_start = 20
      vbox.margin_end = 20
      vbox.append(label)
      vbox.append(ok_button)

      dialog.extra_child = vbox
      dialog.present(parent)
      dialog
    end

    def show_error_dialog(parent, title : String, text : String, message_type : Symbol = :default)
      dialog = Adw::AlertDialog.new(title, text)

      dialog.add_response("close", "OK")
      dialog.default_response = "close"

      appearance = case message_type
                   when :destructive then Adw::ResponseAppearance::Destructive
                   when :suggested then Adw::ResponseAppearance::Suggested
                   else Adw::ResponseAppearance::Default
                   end
      dialog.set_response_appearance("close", appearance)

      dialog.response_signal.connect do |response|
        dialog.force_close
      end

      dialog.present(parent)
      dialog
    end

    def show_overwrite_dialog(parent_window) : String?
      response = nil

      dialog = Adw::AlertDialog.new(
        "File Already Exists",
        "The file already exists. Do you want to overwrite it?"
      )

      dialog.add_response("cancel", "_Cancel")
      dialog.add_response("overwrite", "_Overwrite")
      dialog.set_response_appearance("overwrite", Adw::ResponseAppearance::Destructive)
      dialog.default_response = "overwrite"
      dialog.close_response = "cancel"

      dialog.response_signal.connect do |res|
        response = res
        dialog.force_close
      end

      dialog.present(parent_window)
      response
    end
  end
end
