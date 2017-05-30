require 'spec_helper'

describe YarnParser do
  let(:parser){ YarnParser.new }
  let(:test_file_path) { 'spec/fixtures/files/yarn.lock' }

  describe "rules" do
    it "matches semver versions" do
      rule = parser.rules[:semver]
      expect( "1".match(rule)     ).not_to be_nil
      expect( "1.0".match(rule)   ).not_to be_nil
      expect( "1.0.1".match(rule) ).not_to be_nil
      expect( "1.0.1+build42".match(rule)).not_to be_nil
    end

    it "matches dependency item" do
      rule = parser.rules[:dep]

      m = "acorn-js@^3.0.0:".match(rule)
      expect(m).not_to be_nil
      expect(m[:depname]).to eq('acorn-js')
      expect(m[:selector]).to eq('^3.0.0')
    end

    it "matches dependency item with dots in the name" do
      rule = parser.rules[:dep]

      m = "lodash.isplainobject@^4.0.6:".match(rule)
      expect(m).not_to be_nil
      expect(m[:depname]).to eq('lodash.isplainobject')
      expect(m[:selector]).to eq('^4.0.6')
    end

    it "matches dependency row with single item" do
      rule = parser.rules[:dep]
      m = "babel-traverse@^6.16.0:".match(rule)
      expect(m).not_to be_nil
      expect( m[:depname]  ).to eq('babel-traverse')
      expect( m[:selector] ).to eq('^6.16.0')
    end

    it "matches dependency row with multiple items" do
      rule = parser.rules[:dep]

      m = "babel-traverse@^6.16.0, babel-traverse@^6.18.0, babel-traverse@^6.20.0, babel-traverse@^6.21.0:".match(rule)
      expect(m).not_to be_nil
      expect( m[:depname]  ).to eq('babel-traverse')
      expect( m[:selector] ).to eq('^6.16.0')
    end

    it "matches version row" do
      rule = parser.rules[:version_row]
      m = 'version "6.20.0"'.match(rule)

      expect(m).not_to be_nil
      expect(m[:semver]).to eq('6.20.0')
    end

    it "matches subdepency row" do
      rule = parser.rules[:subdep_row]
      m = 'babel-core "^6.18.0"'.match(rule)
      expect(m).not_to be_nil
      expect(m[:depname]).to eq('babel-core')
      expect(m[:selector]).to eq('^6.18.0')
    end
  end

  let(:product1){
    FactoryGirl.create(
      :product_with_versions,
      name: 'abbrev',
      prod_key: 'abbrev',
      prod_type: Project::A_TYPE_NPM,
      language: Product::A_LANGUAGE_NODEJS,
      version: '1.0.9'
    )
  }

  let(:product2){
    FactoryGirl.create(
      :product_with_versions,
      name: 'acorn-jsx',
      prod_key: 'acorn-jsx',
      prod_type: Project::A_TYPE_NPM,
      language: Product::A_LANGUAGE_NODEJS,
      version: '3.0.1'
    )
  }

  let(:product3){
    FactoryGirl.create(
      :product_with_versions,
      name: 'are-we-there-yet',
      prod_key: 'are-we-there-yet',
      prod_type: Project::A_TYPE_NPM,
      language: Product::A_LANGUAGE_NODEJS,
      version: '1.1.2'
    )
  }

  let(:product4){
    FactoryGirl.create(
      :product_with_versions,
      name: 'block-stream',
      prod_key: 'block-stream',
      prod_type: Project::A_TYPE_NPM,
      language: Product::A_LANGUAGE_NODEJS,
      version: '0.0.9'
    )
  }

  let(:product5){
    FactoryGirl.create(
      :product_with_versions,
      name: 'boom',
      prod_key: 'boom',
      prod_type: Project::A_TYPE_NPM,
      language: Product::A_LANGUAGE_NODEJS,
      version: '2.10.1'
    )
  }

  let(:product6){
    FactoryGirl.create(
      :product_with_versions,
      name: 'readable-stream',
      prod_key: 'readable-stream',
      prod_type: Project::A_TYPE_NPM,
      language: Product::A_LANGUAGE_NODEJS,
      version: '2.2.2'
    )
  }

  let(:product7){
    FactoryGirl.create(
      :product_with_versions,
      name: 'lodash.isplainobject',
      prod_key: 'lodash.isplainobject',
      prod_type: Project::A_TYPE_NPM,
      language: Product::A_LANGUAGE_NODEJS,
      version: '4.0.6'
    )
  }

  describe "parse_file_content" do
    it "extracts correct dependency data from the file" do
      txt = File.read test_file_path
      deps = parser.parse_file_content txt
      expect(deps).not_to be_nil
      expect(deps.size).to eq(7)

      dep = deps[0]
      expect(dep[:name]       ).to eq(product1[:name])
      expect(dep[:version]    ).to eq(product1[:version])
      expect(dep[:deps].size  ).to eq(0)

      dep = deps[1]
      expect(dep[:name]       ).to eq(product2[:name])
      expect(dep[:version]    ).to eq(product2[:version])
      expect(dep[:deps].size  ).to eq(1)

      dep = deps[2]
      expect(dep[:name]       ).to eq(product3[:name])
      expect(dep[:version]    ).to eq(product3[:version])
      expect(dep[:deps].size  ).to eq(2)

      dep = deps[3]
      expect(dep[:name]       ).to eq(product4[:name])
      expect(dep[:version]    ).to eq(product4[:version])
      expect(dep[:deps].size  ).to eq(1)
      expect(dep[:optionalDeps].size ).to eq(1)

      dep = deps[4]
      expect(dep[:name]       ).to eq(product5[:name])
      expect(dep[:version]    ).to eq(product5[:version])
      expect(dep[:deps].size  ).to eq(1)

      dep = deps[5]
      expect(dep[:name]       ).to eq(product6[:name])
      expect(dep[:version]    ).to eq(product6[:version])
      expect(dep[:deps].size  ).to eq(7)

    end
  end

  describe "parse_content" do
    it "parses dependencies and return project" do
      #save products so it could find it from DB
      product1.save
      product2.save
      product3.save
      product4.save
      product5.save
      product6.save
      product7.save

      #run test
      txt = File.read test_file_path
      project = parser.parse_content txt

      expect(project).not_to be_nil
      expect(project.dep_number).to eq(7)

      dep = project.dependencies[0]
      expect(dep[:name]).to eq(product1[:name])
      expect(dep[:version_requested]).to eq(product1[:version])
      expect(dep[:version_current]).to eq(product1[:version])
      expect(dep[:comperator]).to eq('=')

      dep = project.dependencies[1]
      expect(dep[:name]).to eq(product2[:name])
      expect(dep[:version_requested]).to eq(product2[:version])
      expect(dep[:version_current]).to eq(product2[:version])
      expect(dep[:comperator]).to eq('=')

      dep = project.dependencies[2]
      expect(dep[:name]).to eq(product3[:name])
      expect(dep[:version_requested]).to eq(product3[:version])
      expect(dep[:version_current]).to eq(product3[:version])
      expect(dep[:comperator]).to eq('=')

      dep = project.dependencies[3]
      expect(dep[:name]).to eq(product4[:name])
      expect(dep[:version_requested]).to eq(product4[:version])
      expect(dep[:version_current]).to eq(product4[:version])
      expect(dep[:comperator]).to eq('=')

      dep = project.dependencies[4]
      expect(dep[:name]).to eq(product5[:name])
      expect(dep[:version_requested]).to eq(product5[:version])
      expect(dep[:version_current]).to eq(product5[:version])
      expect(dep[:comperator]).to eq('=')

      dep = project.dependencies[5]
      expect(dep[:name]).to eq(product6[:name])
      expect(dep[:version_requested]).to eq(product6[:version])
      expect(dep[:version_current]).to eq(product6[:version])
      expect(dep[:comperator]).to eq('=')

      dep = project.dependencies[6]
      expect(dep[:name]).to eq(product7[:name])
      expect(dep[:version_requested]).to eq(product7[:version])
      expect(dep[:version_current]).to eq(product7[:version])
      expect(dep[:comperator]).to eq('=')


    end
  end

end
