require 'spec_helper'

test_case_url = "https://s3.amazonaws.com/veye_test_env/build2.gradle"

describe GradleParser do

  describe "parse" do

    def fetch_by_name(dependencies, name)
      dependencies.each do |dep|
        return dep if dep.name.eql? name
      end
    end

    it "parse from https the file correctly" do
      parser  = GradleParser.new
      project = parser.parse(test_case_url)
      project.should_not be_nil
    end

    it "parse the file correctly" do
      product_1  = ProductFactory.create_for_maven("com.bazaarvoice.dropwizard", "dropwizard-configurable-assets-bundle", "0.2.0-rc1")
      product_1.save

      parser  = GradleParser.new
      project = parser.parse(test_case_url)
      project.should_not be_nil

      dependency_01 = fetch_by_name( project.dependencies, product_1.artifact_id)
      dependency_01.name.should eql( product_1.artifact_id )
      dependency_01.group_id.should eql(product_1.group_id)
      dependency_01.artifact_id.should eql(product_1.artifact_id)
      dependency_01.prod_key.should eql(product_1.prod_key)
      dependency_01.version_requested.should eql("0.2.0-rc1")
      dependency_01.version_current.should eql(product_1.version)
      dependency_01.version_label.should eql("0.2.0-rc1")
      dependency_01.comperator.should eql("=")
      dependency_01.scope.should eql(Dependency::A_SCOPE_COMPILE)
    end

  end

end

