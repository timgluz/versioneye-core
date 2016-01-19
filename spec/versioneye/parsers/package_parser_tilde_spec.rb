require 'spec_helper'

describe PackageParser do

  describe "parse" do

    it "parse from https the file correctly" do
      parser = PackageParser.new
      project = parser.parse('https://s3.amazonaws.com/veye_test_env/npm_1/package.json')
      project.should_not be_nil
    end

    it "parse from http the file correctly" do

      product1 = create_product('eslint'   , 'eslint'   , '1.1.0', ['0.24.0' , '0.24.1', '1.0.0', '1.1.0' ] )
      product2 = create_product('inquirer' , 'inquirer' , '0.9.0', ['0.9.0' , '0.8.5', '0.8.4', '0.8.3', '0.8.2', '0.8.0', '0.7.3', '0.7.2' ] )
      product3 = create_product('gcloud'   , 'gcloud'   , '0.2.0', ['0.20.0' , '0.21.0', '0.22.0', '0.23.0', '0.24.0', '0.24.1', '0.25.0', '0.25.1', '0.26.0', '0.26.1' ] )
      product4 = create_product('express'  , 'express'   , '4.13.3', ['4.0.0' , '4.1.0', '4.13.3' ] )

      parser = PackageParser.new
      project = parser.parse('https://s3.amazonaws.com/veye_test_env/npm_1/package.json')
      project.should_not be_nil
      project.dependencies.size.should eql(4)

      dep_1 = project.dependencies[0]
      dep_1.name.should eql('eslint')
      dep_1.version_label.should eql('^1.0.0')
      dep_1.version_requested.should eql('1.1.0')
      dep_1.version_current.should eql('1.1.0')
      dep_1.comperator.should eql('^')
      dep_1.outdated?().should be_falsey

      dep_2 = project.dependencies[1]
      dep_2.name.should eql('inquirer')
      dep_2.version_label.should eql('^0.8.0')
      dep_2.version_requested.should eql('0.8.5')
      dep_2.version_current.should eql('0.9.0')
      dep_2.comperator.should eql('^')
      dep_2.outdated?().should be_truthy

      dep_3 = project.dependencies[2]
      dep_3.name.should eql('gcloud')
      dep_3.version_label.should eql('^0.23')
      dep_3.version_requested.should eql('0.23.0')
      dep_3.version_current.should eql('0.26.1')
      dep_3.comperator.should eql('^')
      dep_3.outdated?().should be_truthy

      dep_4 = project.dependencies[3]
      dep_4.name.should eql('express')
      dep_4.version_label.should eql('~4.*')
      dep_4.version_requested.should eql('4.13.3')
      dep_4.version_current.should eql('4.13.3')
      dep_4.comperator.should eql('~')
      dep_4.outdated?().should be_falsey
    end

  end

  def create_product(name, prod_key, version, versions = nil )
    product = Product.new({ :language => Product::A_LANGUAGE_NODEJS, :prod_type => Project::A_TYPE_NPM })
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

end
