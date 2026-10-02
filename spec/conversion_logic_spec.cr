require "./spec_helper"

describe GoblinApp do
  describe ".auto_target_path" do
    it "inserts _converted before the extension" do
      GoblinApp.auto_target_path("/tmp/doc.pdf").should eq "/tmp/doc_converted.pdf"
      GoblinApp.auto_target_path("/tmp/DOC.PDF").should eq "/tmp/DOC_converted.PDF"
    end

    it "leaves paths without a matching extension unchanged" do
      GoblinApp.auto_target_path("/tmp/README").should eq "/tmp/README"
      GoblinApp.auto_target_path("/tmp/archive.tar.gz").should eq "/tmp/archive.tar.gz"
    end
  end

  describe ".magick_args" do
    it "builds monochrome argv with threshold, fax compression and strip by default" do
      options = GoblinApp::ConversionOptions.new
      GoblinApp.magick_args("/tmp/a.pdf", "/tmp/b.pdf", options).should eq [
        "magick", "-density", "300", "/tmp/a.pdf",
        "-threshold", "66%", "-monochrome", "-compress", "Fax",
        "-strip", "/tmp/b.pdf",
      ]
    end

    it "builds grayscale argv without threshold" do
      options = GoblinApp::ConversionOptions.new.copy_with(mode: "grayscale")
      GoblinApp.magick_args("/tmp/a.pdf", "/tmp/b.pdf", options).should eq [
        "magick", "-density", "300", "/tmp/a.pdf",
        "-colorspace", "Gray", "-compress", "Zip",
        "-strip", "/tmp/b.pdf",
      ]
    end

    it "builds grayscale-quality argv with quality" do
      options = GoblinApp::ConversionOptions.new.copy_with(mode: "grayscale_quality", quality: 90)
      GoblinApp.magick_args("/tmp/a.pdf", "/tmp/b.pdf", options).should eq [
        "magick", "-density", "300", "/tmp/a.pdf",
        "-colorspace", "Gray", "-compress", "JPEG", "-quality", "90",
        "-strip", "/tmp/b.pdf",
      ]
    end

    it "builds color argv with quality and honors resolution" do
      options = GoblinApp::ConversionOptions.new.copy_with(mode: "color", quality: 80, resolution: 150)
      GoblinApp.magick_args("/tmp/a.pdf", "/tmp/b.pdf", options).should eq [
        "magick", "-density", "150", "/tmp/a.pdf",
        "-compress", "JPEG", "-quality", "80",
        "-strip", "/tmp/b.pdf",
      ]
    end

    it "omits -strip when metadata stripping is disabled" do
      options = GoblinApp::ConversionOptions.new.copy_with(strip_metadata: false)
      args = GoblinApp.magick_args("/tmp/a.pdf", "/tmp/b.pdf", options)
      args.should_not contain("-strip")
    end

    it "falls back to monochrome for unknown modes" do
      options = GoblinApp::ConversionOptions.new.copy_with(mode: "bogus")
      args = GoblinApp.magick_args("/tmp/a.pdf", "/tmp/b.pdf", options)
      args.should contain("-monochrome")
    end

    it "keeps paths with spaces as single argv entries" do
      options = GoblinApp::ConversionOptions.new
      args = GoblinApp.magick_args("/tmp/my doc.pdf", "/tmp/out file.pdf", options)
      args.should contain("/tmp/my doc.pdf")
      args.should contain("/tmp/out file.pdf")
    end
  end

  describe ".magick_command" do
    it "quotes paths with spaces for copy-pasteable logs" do
      options = GoblinApp::ConversionOptions.new
      GoblinApp.magick_command("/tmp/my doc.pdf", "/tmp/b.pdf", options).should contain "'/tmp/my doc.pdf'"
    end
  end

  describe ".exited_ok? and .exit_code" do
    it "treats exit status 0 as success" do
      GoblinApp.exited_ok?(0).should be_true
      GoblinApp.exit_code(0).should eq 0
    end

    it "decodes nonzero exit codes (status is exit << 8)" do
      GoblinApp.exited_ok?(256).should be_false
      GoblinApp.exit_code(256).should eq 1
      GoblinApp.exit_code(3 << 8).should eq 3
    end

    it "rejects signal deaths (no normal exit, e.g. SIGKILL is status 9)" do
      GoblinApp.exited_ok?(9).should be_false
    end
  end
end
