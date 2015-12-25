require 'spec_helper'

describe BerksfilelockParser do

  describe "parse" do

    def fetch_by_name(dependencies, name)
      dependencies.each do |dep|
        return dep if dep.name.eql? name
      end
    end

    it "reads file correctly from web" do
      parser  = BerksfilelockParser.new
      project = parser.parse "https://s3.amazonaws.com/veye_test_env/Berksfile.lock"
      project.should_not be_nil
    end

    it "parses test file correctly" do
      product1 = ProductFactory.create_for_chef("7-zip", "1.0.2")
      product1.save

      product2 = ProductFactory.create_for_gemfile("dmg", "2.3.0")
      product2.save

      parser  = BerksfilelockParser.new
      project = parser.parse "https://s3.amazonaws.com/veye_test_env/Berksfile.lock"
      project.should_not be_nil

      dep1 = fetch_by_name(project.dependencies, product1.name)
      dep1.name.should eql(product1.name)
      dep1.version_requested.should eql(product1.version)
      dep1.outdated.should be_falsey
      dep1.language.should eq(Product::A_LANGUAGE_CHEF)

      dep2 = fetch_by_name(project.dependencies, product2.name)
      dep2.name.should eql(product2.name)
      dep2.version_requested.should eql(product2.version)
      dep2.outdated.should be_falsey
      dep2.language.should eq(Product::A_LANGUAGE_CHEF)
    end

  end

end
