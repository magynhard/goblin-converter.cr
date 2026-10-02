require "./spec_helper"

describe GoblinApp::ConversionOptions do
  it "has document-conversion defaults" do
    options = GoblinApp::ConversionOptions.new
    options.mode.should eq "monochrome"
    options.resolution.should eq 300
    options.threshold.should eq 66
    options.quality.should eq 75
    options.strip_metadata.should be_true
  end

  describe "#copy_with" do
    it "keeps all values when no overrides given" do
      options = GoblinApp::ConversionOptions.new.copy_with
      options.mode.should eq "monochrome"
      options.resolution.should eq 300
      options.threshold.should eq 66
      options.quality.should eq 75
      options.strip_metadata.should be_true
    end

    it "overrides only the given values" do
      options = GoblinApp::ConversionOptions.new.copy_with(mode: "color", quality: 90)
      options.mode.should eq "color"
      options.quality.should eq 90
      options.resolution.should eq 300
      options.threshold.should eq 66
      options.strip_metadata.should be_true
    end
  end
end

describe GoblinApp::FormData do
  it "starts empty with default options" do
    form = GoblinApp::FormData.new
    form.source_path.should be_nil
    form.target_path.should be_nil
    form.options.mode.should eq "monochrome"
  end

  describe "#copy_with" do
    it "overrides only the given values" do
      form = GoblinApp::FormData.new.copy_with(source_path: "/tmp/a.pdf")
      form.source_path.should eq "/tmp/a.pdf"
      form.target_path.should be_nil
    end
  end
end
