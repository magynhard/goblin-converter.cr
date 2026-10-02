module GoblinApp
  # Pure conversion logic (no GTK widgets involved), covered by specs in spec/.
  # Keep every method free of UI calls so tests run headless.

  # Derives the default target path by inserting "_converted" before
  # the file extension. Returns the input unchanged without extension.
  def self.auto_target_path(source : String) : String
    source.gsub(/\.([a-zA-Z]{3,4})$/, "_converted.\\1")
  end

  # Builds the magick argv (no shell, so paths need no quoting).
  def self.magick_args(source : String, output : String, options : ConversionOptions) : Array(String)
    mode_args = case options.mode
                when "monochrome"
                  ["-threshold", "#{options.threshold}%", "-monochrome", "-compress", "Fax"]
                when "grayscale"
                  ["-colorspace", "Gray", "-compress", "Zip"]
                when "grayscale_quality"
                  ["-colorspace", "Gray", "-compress", "JPEG", "-quality", options.quality.to_s]
                when "color"
                  ["-compress", "JPEG", "-quality", options.quality.to_s]
                else
                  ["-threshold", "#{options.threshold}%", "-monochrome", "-compress", "Fax"]
                end

    strip_args = options.strip_metadata ? ["-strip"] : [] of String
    ["magick", "-density", options.resolution.to_s, source] + mode_args + strip_args + [output]
  end

  # Copy-pasteable shell representation of magick_args for logs.
  def self.magick_command(source : String, output : String, options : ConversionOptions) : String
    magick_args(source, output, options).map { |arg| Process.quote(arg) }.join(" ")
  end

  # Whether the child exited normally with code 0. Unix waitpid
  # statuses encode this in bits (Linux layout); on Windows the status
  # reported by Gio is the plain exit code.
  def self.exited_ok?(status : Int32) : Bool
    {% if flag?(:win32) %}
      status == 0
    {% else %}
      (status & 0x7f) == 0 && ((status >> 8) & 0xff) == 0
    {% end %}
  end

  # Exit code from a waitpid status (Linux layout); on Windows the
  # status already is the plain exit code.
  def self.exit_code(status : Int32) : Int32
    {% if flag?(:win32) %}
      status
    {% else %}
      (status >> 8) & 0xff
    {% end %}
  end
end
