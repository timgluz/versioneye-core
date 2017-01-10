require 'spec_helper'

describe PomParser do

  describe "parse" do

    it "parse from https the file correctly" do
      parser = PomParser.new
      project = parser.parse("https://s3.amazonaws.com/veye_test_env/pom.json")
      expect( project ).to_not be_nil
    end

    it "parse the file correctly" do

      product_1 = ProductFactory.create_for_maven("net.sourceforge.htmlunit", "htmlunit", "2.12")
      product_1.save

      product_2 = ProductFactory.create_for_maven("net.sourceforge.htmlcleaner", "htmlcleaner", "2.4")
      product_2.save

      parser = PomJsonParser.new
      project = parser.parse("https://s3.amazonaws.com/veye_test_env/pom.json")
      expect( project ).to_not be_nil

      expect( project.license ).to eq("MIT")

      dependency_01 = project.dependencies.first
      expect( dependency_01.name).to eql("net.sourceforge.htmlunit:htmlunit")
      expect( dependency_01.group_id).to eql("net.sourceforge.htmlunit")
      expect( dependency_01.artifact_id).to eql("htmlunit")
      expect( dependency_01.version_requested).to eql("2.12")
      expect( dependency_01.version_current).to eql("2.12")
      expect( dependency_01.comperator).to eql("=")

      dependency_02 = project.dependencies[1]
      expect( dependency_02.name).to eql("net.sourceforge.htmlcleaner:htmlcleaner")
      expect( dependency_02.group_id).to eql("net.sourceforge.htmlcleaner")
      expect( dependency_02.artifact_id).to eql("htmlcleaner")
      expect( dependency_02.version_requested).to eql("2.4")
      expect( dependency_02.version_current).to eql("2.4")
      expect( dependency_02.comperator).to eql("=")

    end

  end

end
