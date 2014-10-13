require 'spec_helper'

test_case_url = "https://s3.amazonaws.com/veye_test_env/gradle/build.gradle"

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
      product_1  = ProductFactory.create_for_maven("com.google.guava", "guava", "18.0")
      product_2  = ProductFactory.create_for_maven("junit", "junit", "4.11")

      product_1.save
      product_2.save

      parser = GradleParser.new
      project = parser.parse( test_case_url )
      project.should_not be_nil
      expect(project.dependencies.size).to eq(37)

      dependency_01 = fetch_by_name( project.dependencies, "guava")
      dependency_01.name.should eql(product_1.artifact_id)
      dependency_01.group_id.should eql(product_1.group_id)
      dependency_01.artifact_id.should eql(product_1.artifact_id)
      dependency_01.prod_key.should eql(product_1.prod_key)
      dependency_01.version_requested.should eql("18.0")
      dependency_01.version_current.should eql(product_1.version)
      dependency_01.comperator.should eql("=")

      dependency_02 = fetch_by_name( project.dependencies, "junit")
      dependency_02.name.should eql(product_2.artifact_id)
      dependency_02.group_id.should eql(product_2.group_id)
      dependency_02.artifact_id.should eql(product_2.artifact_id)
      dependency_02.prod_key.should eql(product_2.prod_key)
      dependency_02.version_requested.should eql("4.11")
      dependency_02.version_current.should eql(product_2.version)
      dependency_02.comperator.should eql("=")
    end

  end

end
