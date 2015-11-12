require 'spec_helper'

describe BerksfileParser do

  describe "parse" do

    def fetch_by_name(dependencies, name)
      dependencies.each do |dep|
        return dep if dep.name.eql? name
      end
      nil
    end

    it "reads file correctly from web" do
      parser  = BerksfileParser.new
      project = parser.parse "https://s3.amazonaws.com/veye_test_env/Berksfile"
      project.should_not be_nil
    end

    it "parses test file correctly" do
      product2 = ProductFactory.create_for_chef("dmg", "1.0.0")
      product2.save

      parser  = BerksfileParser.new
      project = parser.parse "https://s3.amazonaws.com/veye_test_env/Berksfile"
      project.should_not be_nil

      dep1 = fetch_by_name(project.dependencies, product2.name)
      dep1.name.should eql(product2.name)

      dep1.version_label.should eql("1.0.0")
      dep1.version_current.should eql("1.0.0")
      dep1.version_requested.should eql("1.0.0")

      dep1.outdated.should be_falsey
      dep1.language.should eq(Product::A_LANGUAGE_CHEF)
    end

  end

end
