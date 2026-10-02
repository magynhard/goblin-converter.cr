require "../prerequisites"
require "../views/main_window"

module GoblinApp
  module Dialogs
    extend self

    # Modern result dialog: heading + status icon + single action button
    # (no duplicated text). The success button is styled green via the
    # app CSS provider (Adwaita has no green response appearance).
    def show_custom_dialog(parent, text : String, title : String = "Info", message_type : Symbol = :default)
      ensure_custom_css
      dialog = Adw::AlertDialog.new(text, nil)

      vbox = Gtk::Box.new(:vertical, 12)
      vbox.margin_top = 6

      case message_type
      when :info
        vbox.append(status_icon("object-select-symbolic", "success"))
      when :error
        vbox.append(status_icon("dialog-error-symbolic", "error"))
      end

      ok_button = Gtk::Button.new(label: "OK")
      ok_button.add_css_class("goblin-success-button") if message_type == :info
      ok_button.clicked_signal.connect do
        dialog.force_close
      end
      vbox.append(ok_button)

      dialog.extra_child = vbox
      dialog.present(parent)
      dialog
    end

    @@css_loaded = false

    # App-wide CSS (loaded once): dark theme-aware green success button,
    # analogous to Adwaita's red destructive button (same _bg_color /
    # _fg_color mechanism, designed for readable white text).
    def self.ensure_custom_css : Nil
      return if @@css_loaded
      display = Gdk::Display.default
      return if display.nil?
      provider = Gtk::CssProvider.new
      provider.load_from_string(<<-CSS)
        .goblin-success-button {
          background-color: @success_bg_color;
          color: @success_fg_color;
          font-weight: bold;
          transition: background-color 150ms ease;
        }
        .goblin-success-button:hover {
          background-color: shade(@success_bg_color, 1.1);
        }
        .goblin-success-button:active {
          background-color: shade(@success_bg_color, 0.9);
        }
      CSS
      Gtk::StyleContext.add_provider_for_display(
        display, provider, Gtk::STYLE_PROVIDER_PRIORITY_APPLICATION.to_u32)
      @@css_loaded = true
    end

    private def status_icon(icon_name : String, css_class : String) : Gtk::Image
      image = Gtk::Image.new_from_icon_name(icon_name)
      image.pixel_size = 48
      image.halign = :center
      image.margin_top = 6
      image.margin_bottom = 6
      image.add_css_class(css_class)
      image
    end

    def show_error_dialog(parent, title : String, text : String, message_type : Symbol = :default)
      dialog = Adw::AlertDialog.new(title, text)

      dialog.add_response("close", "OK")
      dialog.default_response = "close"

      appearance = case message_type
                   when :destructive then Adw::ResponseAppearance::Destructive
                   when :suggested   then Adw::ResponseAppearance::Suggested
                   else                   Adw::ResponseAppearance::Default
                   end
      dialog.set_response_appearance("close", appearance)

      dialog.response_signal.connect do |response|
        dialog.force_close
      end

      dialog.present(parent)
      dialog
    end

    def show_overwrite_dialog(parent_window, &block : Bool ->)
      callback = block

      dialog = Adw::AlertDialog.new(
        GoblinApp.translate("File Already Exists"),
        GoblinApp.translate("The file already exists. Do you want to overwrite it?")
      )

      dialog.add_response("cancel", GoblinApp.translate("_Cancel"))
      dialog.add_response("overwrite", GoblinApp.translate("_Overwrite"))
      dialog.set_response_appearance("overwrite", Adw::ResponseAppearance::Destructive)
      dialog.default_response = "overwrite"
      dialog.close_response = "cancel"

      dialog.response_signal.connect do |res|
        callback.call(res == "overwrite")
        dialog.force_close
      end

      dialog.present(parent_window)
    end

    # Progress dialog (no OK button) for ongoing work.
    # Closed programmatically via `force_close`. Stays closeable so
    # closing always works; early user dismissal is harmless.
    def show_progress_dialog(parent)
      dialog = Adw::AlertDialog.new(GoblinApp.translate("Converting"), GoblinApp.translate("Please wait..."))

      spinner = Gtk::Spinner.new
      spinner.start
      spinner.halign = :center
      spinner.margin_top = 10
      spinner.margin_bottom = 10
      spinner.set_size_request(32, 32)

      dialog.extra_child = spinner
      dialog.present(parent)
      dialog
    end
  end
end
