require 'spec_helper'

test_case_url = "https://s3.amazonaws.com/veye_test_env/sbt_2/build.sbt"

describe SbtParser do

  describe "parse" do

    def fetch_by_name(dependencies, name)
      dependencies.each do |dep|
        return dep if dep.artifact_id.eql? name
      end
      nil
    end

    it "parse from https the file correctly" do
      parser  = SbtParser.new
      project = parser.parse( test_case_url )
      project.should_not be_nil
    end

    it "parse the file correctly" do
      product_1  = ProductFactory.create_for_maven("org.apache.kafka", "kafka_2.10", "0.9.0.1")
      product_2  = ProductFactory.create_for_maven("org.scalatest", "scalatest_2.10", "2.2.4")
      product_3  = ProductFactory.create_for_maven("org.scalatest", "scalatest", "1.0.0")

      product_1.save
      product_2.save
      product_3.save

      parser = SbtParser.new
      project = parser.parse( test_case_url )
      project.should_not be_nil
      expect(project.dependencies.size).to eq(3)

      dependency_01 = fetch_by_name( project.dependencies, product_1.artifact_id)
      dependency_01.name.should eql("kafka")
      dependency_01.group_id.should eql(product_1.group_id)
      dependency_01.artifact_id.should eql(product_1.artifact_id)
      dependency_01.prod_key.should eql(product_1.prod_key)
      dependency_01.version_requested.should eql("0.9.0.1")
      dependency_01.version_current.should eql(product_1.version)
      dependency_01.comperator.should eql("=")
      dependency_01.scope.should eql('compile')

      dependency_02 = fetch_by_name( project.dependencies, product_2.artifact_id)
      dependency_02.name.should eql('scalatest')
      dependency_02.group_id.should eql(product_2.group_id)
      dependency_02.artifact_id.should eql(product_2.artifact_id)
      dependency_02.prod_key.should eql(product_2.prod_key)
      dependency_02.version_requested.should eql('2.2.4')
      dependency_02.version_current.should eql(product_2.version)
      dependency_02.comperator.should eql("=")
      dependency_02.scope.should eql('test')

    end

  end

end
