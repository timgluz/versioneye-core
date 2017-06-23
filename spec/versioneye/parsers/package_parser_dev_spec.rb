require 'spec_helper'

describe PackageParser do

  before(:each) do
    Product.delete_all
  end

  after(:each) do
    Product.delete_all
  end

  describe "parse" do

    it "parse from https the file correctly" do
      parser = PackageParser.new
      project = parser.parse("https://s3.amazonaws.com/veye_test_env/package_dev.json")
      expect( project ).not_to be_nil
    end

    it "parse from http the file correctly" do
      product1  = create_product('connect-redis', 'connect-redis', '1.3.0')
      product2  = create_product('redis'     , 'redis'     , '1.3.0')
      product3  = create_product('memcache'  , 'memcache'  , '1.4.0')
      product4  = create_product('mongo'     , 'mongo'     , '1.1.7')
      product5  = create_product('mongoid'   , 'mongoid'   , '1.1.7')
      product6  = create_product('express'   , 'express'   , '2.4.7', ['2.4.0' , '2.4.6', '2.4.7' ] )
      product7  = create_product('fs-ext'    , 'fs-ext'    , '2.4.7', ['0.2.0' , '0.2.7', '2.4.7' ] )
      product8  = create_product('jade'      , 'jade'      , '2.4.7', ['0.2.0' , '0.2.7', '2.4.7' ] )
      product9  = create_product('mailer'    , 'mailer'    , '0.7.0', ['0.6.0' , '0.6.1', '0.6.5', '0.6.9', '0.7.0'])
      product10 = create_product('markdown'  , 'markdown'  , '0.4.0', ['0.2.0' , '0.3.0', '0.4.0' ] )
      product11 = create_product('mu2'       , 'mu2'       , '0.6.0', ['0.5.10', '0.5.0', '0.6.0' ] )
      product12 = create_product('pg'        , 'pg'        , '0.6.6', ['0.5.0' , '0.6.1' ] )
      product13 = create_product('pg_connect', 'pg_connect', '0.6.9', ['0.5.0' , '0.6.1' ] )

      parser = PackageParser.new
      project = parser.parse("https://s3.amazonaws.com/veye_test_env/package_dev.json")
      expect( project ).not_to be_nil
      expect( project.dependencies.size ).to eql(13)

      dep_01 = project.dependencies.first
      expect( dep_01.name ).to              eql(product1[:name])
      expect( dep_01.version_requested ).to eql("1.3.0")
      expect( dep_01.version_current ).to   eql("1.3.0")
      expect( dep_01.comperator ).to        eql("=")

      dep_02 = project.dependencies[1]
      expect( dep_02.name ).to              eql(product2[:name])
      expect( dep_02.version_requested ).to eql("1.3.0")
      expect( dep_02.version_current ).to   eql("1.3.0")
      expect( dep_02.comperator ).to        eql("=")

      dep_03 = project.dependencies[2]
      expect( dep_03.name ).to              eql(product3[:name])
      expect( dep_03.version_requested ).to eql("1.4.0")
      expect( dep_03.version_current ).to   eql("1.4.0")
      expect( dep_03.comperator ).to        eql("=")

      dep_04 = project.dependencies[3]
      expect( dep_04.name ).to              eql(product4[:name])
      expect( dep_04.version_requested ).to eql("1.1.7")
      expect( dep_04.version_current ).to   eql("1.1.7")
      expect( dep_04.comperator ).to        eql("=")

      dep_05 = project.dependencies[4]
      expect( dep_05.name ).to              eql(product5[:name])
      expect( dep_05.version_requested ).to eql("1.1.7")
      expect( dep_05.version_current ).to   eql("1.1.7")
      expect( dep_05.comperator ).to        eql("=")

      dep_06 = project.dependencies[5]
      expect( dep_06.name ).to              eql(product6[:name])
      expect( dep_06.version_requested ).to eql("2.4.7")
      expect( dep_06.version_current ).to   eql("2.4.7")
      expect( dep_06.comperator ).to        eql("=")

      dep_07 = project.dependencies[6]
      expect( dep_07.name ).to              eql(product7[:name])
      expect( dep_07.version_requested ).to eql("0.2.7")
      expect( dep_07.version_current ).to   eql("2.4.7")
      expect( dep_07.comperator ).to        eql("=")

      dep_08 = project.dependencies[7]
      expect( dep_08.name ).to              eql(product8[:name])
      expect( dep_08.version_requested ).to eql("0.2.7")
      expect( dep_08.version_current ).to   eql("2.4.7")
      expect( dep_08.comperator ).to        eql("~")

      dep_09 = project.dependencies[8]
      expect( dep_09.name ).to              eql(product9[:name])
      expect( dep_09.version_requested ).to eql("0.6.9")
      expect( dep_09.version_current ).to   eql("0.7.0")
      expect( dep_09.comperator ).to        eql("=")

      dep_10 = project.dependencies[9]
      expect( dep_10.name ).to              eql(product10[:name])
      expect( dep_10.version_requested ).to eql("0.2.0")
      expect( dep_10.version_current ).to   eql("0.4.0")
      expect( dep_10.comperator ).to        eql("<")

      dep_11 = project.dependencies[10]
      expect( dep_11.name ).to              eql(product11[:name])
      expect( dep_11.version_requested ).to eql("0.6.0")
      expect( dep_11.version_current ).to   eql("0.6.0")
      expect( dep_11.comperator ).to        eql(">")

      dep_12 = project.dependencies[11]
      expect( dep_12.name ).to              eql(product12[:name])
      expect( dep_12.version_requested ).to eql("0.6.6")
      expect( dep_12.version_current ).to   eql("0.6.6")
      expect( dep_12.comperator ).to        eql(">=")

      dep_13 = project.dependencies[12]
      expect( dep_13.name ).to              eql(product13[:name])
      expect( dep_13.version_requested ).to eql("0.6.9")
      expect( dep_13.version_current ).to   eql("0.6.9")
      expect( dep_13.comperator ).to        eql("<=")

    end

  end

  def create_product(name, prod_key, version, versions = nil )
    product = Product.new({
      :language => Product::A_LANGUAGE_NODEJS,
      :prod_type => Project::A_TYPE_NPM
    })

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
