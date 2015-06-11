require 'spec_helper'

test_case_url = "https://s3.amazonaws.com/veye_test_env/build.sbt"

describe SbtParser do

  describe "parse" do

    def fetch_by_name(dependencies, name)
      dependencies.each do |dep|
        return dep if dep.name.eql? name
      end
    end

    it "parse from https the file correctly" do
      parser  = SbtParser.new
      project = parser.parse( test_case_url )
      project.should_not be_nil
    end

    it "parse the file correctly" do
      product_1  = ProductFactory.create_for_maven("net.java.dev.jets3t", "jets3t", "0.9.0")
      product_2  = ProductFactory.create_for_maven("org.scalamock", "scalamock-specs2-support", "3.0.1")
      product_3  = ProductFactory.create_for_maven("org.ostermiller", "utils", "1.07.00")

      product_1.save
      product_2.save
      product_3.save

      parser = SbtParser.new
      project = parser.parse( test_case_url )
      project.should_not be_nil
      expect(project.dependencies.size).to eq(29)

      dependency_01 = fetch_by_name( project.dependencies, product_1.artifact_id)
      dependency_01.name.should eql(product_1.artifact_id)
      dependency_01.group_id.should eql(product_1.group_id)
      dependency_01.artifact_id.should eql(product_1.artifact_id)
      dependency_01.prod_key.should eql(product_1.prod_key)
      dependency_01.version_requested.should eql("0.9.0")
      dependency_01.version_current.should eql(product_1.version)
      dependency_01.comperator.should eql("=")
      dependency_01.scope.should eql("compile")

      dependency_02 = fetch_by_name( project.dependencies, product_2.artifact_id)
      dependency_02.name.should eql(product_2.artifact_id)
      dependency_02.group_id.should eql(product_2.group_id)
      dependency_02.artifact_id.should eql(product_2.artifact_id)
      dependency_02.prod_key.should eql(product_2.prod_key)
      dependency_02.version_requested.should eql("3.0.1")
      dependency_02.version_current.should eql(product_2.version)
      dependency_02.comperator.should eql("=")
      dependency_02.scope.should eql("test")

      dependency_03 = fetch_by_name( project.dependencies, product_3.artifact_id)
      dependency_03.name.should eql(product_3.artifact_id)
      dependency_03.group_id.should eql(product_3.group_id)
      dependency_03.artifact_id.should eql(product_3.artifact_id)
      dependency_03.prod_key.should eql(product_3.prod_key)
      dependency_03.version_requested.should eql("1.07.00")
      dependency_03.version_current.should eql(product_3.version)
      dependency_03.comperator.should eql("=")
      dependency_03.scope.should eql("compile")

    end

    it 'parse from url' do 
      parser = SbtParser.new
      project = parser.parse( "https://s3.amazonaws.com/veye_test_env/sbt_1/build.sbt" )
      project.should_not be_nil
      expect(project.dependencies.size).to eq(22)

      dep = dep_by_GA('com.typesafe.akka', 'akka-actor', project)
      expect( dep ).to_not be_nil 
      expect( dep.version_requested ).to eq('2.3.11')

      dep = dep_by_GA('io.spray', 'spray-can', project)
      expect( dep ).to_not be_nil 
      expect( dep.version_requested ).to eq('1.3.3')
      expect( dep.scope ).to eq('compile')

      dep = dep_by_GA('io.spray', 'spray-testkit', project)
      expect( dep ).to_not be_nil 
      expect( dep.version_requested ).to eq('1.3.3')
      expect( dep.scope ).to eq('test')

      

      dep = dep_by_GA('com.hybris.service-sdk.libraries', 'logging', project)
      expect( dep ).to_not be_nil 
      expect( dep.version_requested ).to eq('3.12.0')

      dep = dep_by_GA('', '', project)
    end

  end


  def dep_by_GA(group, artifact, project)
    project.dependencies.each do |dep| 
      return dep if dep.group_id.eql?(group) && dep.artifact_id.eql?(artifact)
    end
    nil 
  end

end
