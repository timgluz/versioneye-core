require 'spec_helper'

describe BiicodeParser do

  test_case_url = "https://s3.amazonaws.com/veye_test_env/biicode.conf"


  describe "parse" do

    def fetch_by_name(dependencies, name)
      dependencies.each do |dep|
        return dep if dep.name.eql? name
      end
    end

    it "parse from https the file correctly" do
      parser = BiicodeParser.new
      project = parser.parse( test_case_url )
      project.should_not be_nil
    end

    it "parse from http the file correctly" do
      product1 = ProductFactory.create_for_biicode("lasote/lasote/openssl/v1.0.2", "0")
      product1.versions.push( Version.new({version: "1"}) )
      product1.save

      product2 = ProductFactory.create_for_biicode("fenix/fenix/poco/v1.6.0", "1")
      product2.save

      product3 = ProductFactory.create_for_biicode("lasote/lasote/libevent/master", "2")
      product3.save

      parser  = BiicodeParser.new
      project = parser.parse( test_case_url )
      project.should_not be_nil
      project.dependencies.size.should eql(4)

      dep_1 = fetch_by_name project.dependencies, "lasote/lasote/openssl/v1.0.2"
      dep_1.name.should eql("lasote/lasote/openssl/v1.0.2")
      dep_1.version_requested.should eql('0')
      dep_1.version_current.should eql("1")
      dep_1.version_label.should eql('0')
      dep_1.comperator.should eql("=")
      dep_1.outdated.should be_truthy

      dep_2 = fetch_by_name project.dependencies, "fenix/fenix/poco/v1.6.0"
      dep_2.name.should eql("fenix/fenix/poco/v1.6.0")
      dep_2.version_requested.should eql("1")
      dep_2.version_current.should eql("1")
      dep_2.comperator.should eql("=")
      dep_2.outdated.should be_falsey

      dep_3 = fetch_by_name project.dependencies, "nat/nat/nat/master"
      dep_3.name.should eql("nat/nat/nat/master")
      dep_3.version_requested.should eql("0")
      dep_3.version_current.should be_nil
      dep_3.comperator.should eql("=")
      dep_3.unknown?.should be_truthy

      dep_4 = fetch_by_name project.dependencies, "lasote/lasote/libevent/master"
      dep_4.name.should eql("lasote/lasote/libevent/master")
      dep_4.version_requested.should eql("2")
      dep_4.version_current.should eql('2')
      dep_4.comperator.should eql("=")
      dep_4.unknown?.should be_falsey
      dep_4.outdated.should be_falsey
    end

  end


end
