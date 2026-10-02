require "gettext"

{% if flag?(:win32) %}
  # On Windows (MSVC + gvsbuild) the gettext C functions live in intl.dll,
  # not in the C runtime: link its import library wherever LibC is used.
  @[Link("intl")]
  lib LibC
  end
{% end %}

module GoblinApp
  VERSION = {{read_file("./shard.yml").split("version: ")[1].split("\n")[0]}}

  # Initialize gettext for i18n
  locale_dir = File.join(File.dirname(__FILE__), "..", "..", "po")
  {% if flag?(:win32) %}
    # MSVC numbers locale categories differently than glibc (which the
    # gettext shard assumes: LC::ALL = 6). On MSVC, LC_ALL = 0; passing 6
    # triggers the UCRT invalid-parameter handler and aborts the process.
    LibC.setlocale(0, "")
  {% else %}
    Gettext.setlocale(Gettext::LC::ALL, "")
  {% end %}
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
