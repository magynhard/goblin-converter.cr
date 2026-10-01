require "libadwaita"
require "gettext"

require "./modules/prerequisites"
require "./modules/functions/dialogs"
require "./modules/functions/open_file_dialog"
require "./modules/views/main_window"

module GoblinApp
  class App < Adw::Application
    def initialize
      super(application_id: "de.magynhard.GoblinConverter", flags: Gio::ApplicationFlags::None)
    end

    @[GObject::Virtual]
    def activate
      MainWindow.new(self)
    end
  end
end

exit(GoblinApp::App.new.run)
