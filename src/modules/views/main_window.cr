require "../prerequisites"
require "../functions/dialogs"
require "../functions/open_file_dialog"
require "./conversion_mode_group"
require "./source_file_group"
require "./target_file_group"
require "./convert_button_group"

module GoblinApp
  struct ConversionOptions
    property mode : String
    property resolution : Int32
    property threshold : Int32
    property quality : Int32
    property strip_metadata : Bool

    def initialize(
      @mode = "monochrome",
      @resolution = 300,
      @threshold = 66,
      @quality = 75,
      @strip_metadata = true
    )
    end

    def copy_with(mode : String? = nil, resolution : Int32? = nil, threshold : Int32? = nil, quality : Int32? = nil, strip_metadata : Bool? = nil) : ConversionOptions
      ConversionOptions.new(
        mode: mode || self.mode,
        resolution: resolution || self.resolution,
        threshold: threshold || self.threshold,
        quality: quality || self.quality,
        strip_metadata: strip_metadata || self.strip_metadata
      )
    end
  end

  struct FormData
    property source_path : String?
    property target_path : String?
    property options : ConversionOptions

    def initialize(
      @source_path = nil,
      @target_path = nil,
      @options = ConversionOptions.new
    )
    end

    def copy_with(source_path : String? = nil, target_path : String? = nil, options : ConversionOptions? = nil) : FormData
      FormData.new(
        source_path: source_path || self.source_path,
        target_path: target_path || self.target_path,
        options: options || self.options
      )
    end
  end

  class MainWindow
    @app : Gtk::Application
    @window : Gtk::ApplicationWindow
    @form_data : FormData = FormData.new

    # UI references for cross-module access
    property source_file_row : Adw::ActionRow? = nil
    property output_entry_row : Adw::ActionRow? = nil

    def initialize(@app)
      @window = Gtk::ApplicationWindow.new(@app)
      @window.title = "Goblin Converter"
      @window.resizable = false
      @window.set_default_size(700, 600)

      vbox = Gtk::Box.new(:vertical, 10)
      vbox.margin_top = 20
      vbox.margin_bottom = 20
      vbox.margin_start = 20
      vbox.margin_end = 20

      create_menu
      create_conversion_mode_group(vbox)
      create_source_file_group(vbox)
      create_target_file_group(vbox)
      create_convert_button_group(vbox)

      @window.child = vbox
      @window.present
    end

    private def create_menu
      header_bar = Gtk::HeaderBar.new

      header_box = Gtk::Box.new(:vertical, 0)

      main_title = Gtk::Label.new
      main_title.markup = %Q(<span font_weight="bold" font_size="11000">Goblin Converter</span>)
      main_title.halign = :center

      sub_title = Gtk::Label.new
      sub_title.markup = %Q(<span font_size="8000" foreground="gray">#{GoblinApp.translate("A simple document converter")}</span>)
      sub_title.halign = :center
      sub_title.ellipsize = Pango::EllipsizeMode::Middle
      sub_title.max_width_chars = 50

      header_box.append(main_title)
      header_box.append(sub_title)

      header_bar.title_widget = header_box

      burger_menu = Gtk::MenuButton.new
      burger_menu.icon_name = "open-menu-symbolic"

      popover = Gtk::PopoverMenu.new
      burger_menu.popover = popover

      menu_model = Gio::Menu.new
      menu_model.append(GoblinApp.translate("About"), "app.about")

      popover.menu_model = menu_model

      about_action = Gio::SimpleAction.new("about", nil)
      about_action.activate_signal.connect do
        show_about_dialog
      end
      @app.add_action(about_action)

      header_bar.pack_end(burger_menu)

      @window.titlebar = header_bar
    end

    private def show_about_dialog
      about = Adw::AboutDialog.new(
        application_name: "Goblin Converter",
        application_icon: "de.magynhard.GoblinConverter",
        version: GoblinApp::VERSION,
        website: "https://github.com/magynhard/goblin-converter.cr",
        issue_url: "https://github.com/magynhard/goblin-converter.cr/issues",
        developers: ["Matthäus J. N. Beyrle <goblin-converter.github.com@mail.magynhard.de>"],
        license_type: Gtk::License::MitX11,
        copyright: "© 2024 Matthäus J. N. Beyrle"
      )
      about.present(@window)
    end
  end
end
