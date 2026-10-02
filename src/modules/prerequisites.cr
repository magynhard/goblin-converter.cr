require "gettext"

module GoblinApp
  VERSION = {{read_file("./shard.yml").split("version: ")[1].split("\n")[0]}}

  # Initialize gettext for i18n
  locale_dir = File.join(File.dirname(__FILE__), "..", "..", "po")
  Gettext.setlocale(Gettext::LC::ALL, "")
  Gettext.bindtextdomain("de.magynhard.GoblinConverter", locale_dir)
  Gettext.textdomain("de.magynhard.GoblinConverter")

  # Helper for translations - module function callable as GoblinApp.translate(...)
  def self.translate(text : String) : String
    Gettext.gettext(text)
  end

  # Debug logger to stdout with timestamp prefix - always active
  def self.log(message : String) : Nil
    timestamp = Time.local.to_s("%Y-%m-%d %H:%M:%S")
    STDOUT.puts("[#{timestamp}] #{message}")
    STDOUT.flush
  end
end
