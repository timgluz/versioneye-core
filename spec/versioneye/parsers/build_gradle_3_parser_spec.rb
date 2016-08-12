require 'spec_helper'

test_case_url = "https://s3.amazonaws.com/veye_test_env/gradle_3/build.gradle"

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
      product_1  = ProductFactory.create_for_maven("com.android.support", "appcompat-v7", "23.4.0")
      product_1.save

      product_2  = ProductFactory.create_for_maven("com.android.support", "support-annotations", "23.4.0")
      product_2.save

      parser  = GradleParser.new
      project = parser.parse(test_case_url)
      project.should_not be_nil

      dependency_01 = fetch_by_name( project.dependencies, product_1.artifact_id)
      dependency_01.name.should eql( product_1.artifact_id )
      dependency_01.group_id.should eql(product_1.group_id)
      dependency_01.artifact_id.should eql(product_1.artifact_id)
      dependency_01.prod_key.should eql(product_1.prod_key)
      dependency_01.version_requested.should eql('23.4.0')
      dependency_01.version_current.should eql('23.4.0')
      dependency_01.version_label.should eql('23.4.0')
      dependency_01.comperator.should eql("=")
      dependency_01.scope.should eql(Dependency::A_SCOPE_COMPILE)

      dependency_02 = fetch_by_name( project.dependencies, product_2.artifact_id)
      dependency_02.name.should eql( product_2.artifact_id )
      dependency_02.group_id.should eql(product_2.group_id)
      dependency_02.artifact_id.should eql(product_2.artifact_id)
      dependency_02.prod_key.should eql(product_2.prod_key)
      dependency_02.version_requested.should eql('23.4.0')
      dependency_02.version_current.should eql('23.4.0')
      dependency_02.version_label.should eql('23.4.0')
      dependency_02.comperator.should eql("=")
      dependency_02.scope.should eql(Dependency::A_SCOPE_COMPILE)
    end

  end

end
