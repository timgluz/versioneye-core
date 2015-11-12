require 'spec_helper'

describe MetadataParser do

  describe "parse" do

    it "parse from https the file correctly" do
      parser = MetadataParser.new
      project = parser.parse("https://s3.amazonaws.com/veye_test_env/metadata.rb")
      project.should_not be_nil
    end

    it "parse from http the file correctly" do
      product1 = ProductFactory.create_for_chef("hybris_maven", "0.2.0")
      product1.versions.push( Version.new({version: "0.0.1"}) )
      product1.save

      product2 = ProductFactory.create_for_chef("hybris_jdk", "0.2.1")
      product2.save

      product3 = ProductFactory.create_for_chef("hybris_firefox", "0.8.0")
      product3.save

      product4 = ProductFactory.create_for_chef("hybris_dash", "0.3.6")
      product4.save

      product5 = ProductFactory.create_for_chef("rpi_base", "0.3.6")
      product5.save

      product6 = ProductFactory.create_for_chef("rpi_users", "0.5.0")
      product6.save

      product7 = ProductFactory.create_for_chef("rpi_jenkins", "0.2.24")
      product7.save


      parser  = MetadataParser.new
      project = parser.parse("https://s3.amazonaws.com/veye_test_env/metadata.rb")
      project.should_not be_nil
      expect( project.name ).to eq('env_albino_rpi_infra')
      expect( project.license ).to eq('All rights reserved')
      expect( project.description ).to eq('Environment cookbook for template_infra')
      expect( project.version ).to eq('0.1.12')
      project.dependencies.size.should eql(7)

      dep_1 = project.dependencies.first
      dep_1.name.should eql("hybris_maven")
      dep_1.version_requested.should eql("0.2.0")
      dep_1.comperator.should eql("=")
      expect( dep_1.language ).to eql(Product::A_LANGUAGE_CHEF)

      dep_2 = project.dependencies[1]
      dep_2.name.should eql("hybris_jdk")
      dep_2.version_requested.should eql("0.2.1")
      dep_2.version_current.should eql("0.2.1")
      dep_2.comperator.should eql("=")

      dep_3 = project.dependencies[2]
      dep_3.name.should eql("hybris_firefox")
      dep_3.version_requested.should eql("0.8.0")
      dep_3.version_current.should eql("0.8.0")
      dep_3.version_label.should eql("0.8.0")
      dep_3.comperator.should eql("=")

      dep_4 = project.dependencies[3]
      dep_4.name.should eql("hybris_dash")
      dep_4.version_requested.should eql("0.3.6")
      dep_4.version_current.should eql("0.3.6")
      dep_4.version_label.should eql("0.3.6")
      dep_4.comperator.should eql("=")

      dep_5 = project.dependencies[4]
      dep_5.name.should eql("rpi_base")
      dep_5.version_requested.should eql("0.3.6")
      dep_5.version_current.should eql("0.3.6")
      dep_5.version_label.should eql("0.3.6")
      dep_5.comperator.should eql("=")

      dep_6 = project.dependencies[5]
      dep_6.name.should eql("rpi_users")
      dep_6.version_requested.should eql("0.5.0")
      dep_6.version_current.should eql("0.5.0")
      dep_6.version_label.should eql("0.5.0")
      dep_6.comperator.should eql("=")
      dep_6.release.should_not be_nil
      dep_6.release.should be_truthy

      dep_7 = project.dependencies[6]
      dep_7.name.should eql("rpi_jenkins")
      dep_7.version_requested.should eql("0.2.24")
      dep_7.version_current.should eql("0.2.24")
      dep_7.version_label.should eql("0.2.24")
      dep_7.comperator.should eql("=")
    end

  end

end
