require 'spec_helper'

describe RequirementsParser do

  describe "parse" do

    it "parse from https the file correctly" do
      parser = RequirementsParser.new
      project = parser.parse("https://s3.amazonaws.com/veye_test_env/python_2/requirements.txt")
      project.should_not be_nil
    end

    it "parse from http the file correctly" do
      product1  = create_product('anyjson', 'anyjson'  , '1.0.0', ['0.3.3', '0.3.4', '1.0.0' ])

      parser = RequirementsParser.new
      project = parser.parse("https://s3.amazonaws.com/veye_test_env/python_2/requirements.txt")
      project.should_not be_nil
      project.dependencies.size.should eql(49)

      dep_01 = fetch_by_prod_key 'anyjson', project.dependencies
      dep_01.name.should eql("anyjson")
      dep_01.version_requested.should eql("0.3.3")
      dep_01.version_current.should eql("1.0.0")
      dep_01.comperator.should eql("==")
      dep_01.version_label.should eql('==0.3.3')
      dep_01.outdated.should be_truthy 
    end

  end

  
  def create_product(name, prod_key, version, versions = nil )
    product = Product.new({ :language => Product::A_LANGUAGE_PYTHON, :prod_type => Project::A_TYPE_PIP })
    product.name = name
    product.prod_key = prod_key
    product.version = version
    product.add_version( version )
    product.save

    return product if !versions

    versions.each do |ver|
      product.add_version( ver )
    end
    product.save

    product
  end

  
  def fetch_by_prod_key( name, dependencies )
    dependencies.each do |dep| 
      return dep if dep.prod_key.eql?(name)
    end
    nil 
  end


end
