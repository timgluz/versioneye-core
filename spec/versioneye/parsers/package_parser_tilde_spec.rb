require 'spec_helper'

describe PackageParser do
  let(:parser){ PackageParser.new }
  let(:test_file_url){ 'https://s3.amazonaws.com/veye_test_env/npm_1/package.json'}

  describe "parse" do

    it "parse from https the file correctly" do
      project = parser.parse test_file_url
      expect( project ).not_to be_nil
    end

    it "parse from http the file correctly" do

      product1 = create_product('eslint'   , 'eslint'   , '1.1.0', ['0.24.0' , '0.24.1', '1.0.0', '1.1.0' ] )
      product2 = create_product('inquirer' , 'inquirer' , '0.9.0', ['0.9.0' , '0.8.5', '0.8.4', '0.8.3', '0.8.2', '0.8.0', '0.7.3', '0.7.2' ] )
      product3 = create_product('gcloud'   , 'gcloud'   , '0.2.0', ['0.20.0' , '0.21.0', '0.22.0', '0.23.0', '0.24.0', '0.24.1', '0.25.0', '0.25.1', '0.26.0', '0.26.1' ] )
      product4 = create_product('express'  , 'express'   , '4.13.3', ['4.0.0' , '4.1.0', '4.13.3' ] )

      project = parser.parse test_file_url
      expect( project ).not_to be_nil
      expect( project.dependencies.size ).to eql(4)

      dep_1 = project.dependencies[0]
      expect( dep_1.name ).to               eql(product1[:name])
      expect( dep_1.version_label ).to      eql('^1.0.0')
      expect( dep_1.version_requested ).to  eql('1.1.0')
      expect( dep_1.version_current ).to    eql('1.1.0')
      expect( dep_1.comperator ).to         eql('^')
      expect( dep_1.outdated? ).to          be_falsey

      dep_2 = project.dependencies[1]
      expect( dep_2.name ).to               eql(product2[:name])
      expect( dep_2.version_label ).to      eql('^0.8.0')
      expect( dep_2.version_requested ).to  eql('0.8.5')
      expect( dep_2.version_current ).to    eql('0.9.0')
      expect( dep_2.comperator ).to         eql('^')
      expect( dep_2.outdated? ).to          be_truthy

      dep_3 = project.dependencies[2]
      expect( dep_3.name ).to               eql(product3[:name])
      expect( dep_3.version_label ).to      eql('^0.23')
      expect( dep_3.version_requested ).to  eql('0.23.0')
      expect( dep_3.version_current ).to    eql('0.26.1')
      expect( dep_3.comperator ).to         eql('^')
      expect( dep_3.outdated? ).to          be_truthy

      dep_4 = project.dependencies[3]
      expect( dep_4.name ).to               eql(product4[:name])
      expect( dep_4.version_label ).to      eql('~4.*')
      expect( dep_4.version_requested ).to  eql('4.13.3')
      expect( dep_4.version_current ).to    eql('4.13.3')
      expect( dep_4.comperator ).to         eql('~')
      expect( dep_4.outdated? ).to          be_falsey
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
