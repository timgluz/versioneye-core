require 'spec_helper'

describe GopkgParser do
  let(:parser){ GopkgParser.new }
  let(:test_content){ File.read 'spec/fixtures/files/golang/Gopkg.toml' }

  let(:prod1){
    Product.new(
      language: Product::A_LANGUAGE_GO,
      prod_type: Project::A_TYPE_GODEP,
      prod_key:  'github.com/Masterminds/semver',
      name: 'github.com/Masterminds/semver',
      version: '2.0.0'
    )
  }

  let(:prod2){
    Product.new(
      language: Product::A_LANGUAGE_GO,
      prod_type: Project::A_TYPE_GODEP,
      prod_key:  'github.com/Masterminds/vcs',
      name: 'github.com/Masterminds/vcs',
      version: '1.11.0'
    )
  }

  let(:prod3){
    Product.new(
      language: Product::A_LANGUAGE_GO,
      prod_type: Project::A_TYPE_GODEP,
      prod_key:  'github.com/go-yaml/yaml',
      name: 'github.com/go-yaml/yaml',
      version: '2.3.0'
    )
  }

  let(:prod4){
    Product.new(
      language: Product::A_LANGUAGE_GO,
      prod_type: Project::A_TYPE_GODEP,
      prod_key:  'github.com/pelletier/go-toml',
      name: 'github.com/pelletier/go-toml',
      version: '1.4.0'
    )
  }

  let(:prod5){
    Product.new(
      language: Product::A_LANGUAGE_GO,
      prod_type: Project::A_TYPE_GODEP,
      prod_key:  'github.com/pkg/errors',
      name: 'github.com/pkg/errors',
      version: '0.8.0'
    )
  }


  context "parse_content" do
    before do
      prod1.save
      prod2.save
      prod3.save
      prod4.save
      prod5.save
    end


    it "parses testfile correctly" do
      proj = parser.parse_content test_content
      expect(proj).not_to be_nil
      expect(proj.dependencies.size).to eq(5)

      dep1 = proj.dependencies[0]
      expect(dep1).not_to be_nil
      expect(dep1[:language]).to eq(prod1[:language])
      expect(dep1[:prod_key]).to eq(prod1[:prod_key])
      expect(dep1[:version_label]).to eq('2.x')
      expect(dep1[:version_requested]).to eq('0.0.0+NA')
      expect(dep1[:outdated]).to be_truthy

      dep2 = proj.dependencies[1]
      expect(dep2).not_to be_nil
      expect(dep2[:language]).to eq(prod2[:language])
      expect(dep2[:prod_key]).to eq(prod2[:prod_key])
      expect(dep2[:version_label]).to eq('1.11.0')
      expect(dep2[:version_requested]).to eq('0.0.0+NA')
      expect(dep2[:outdated]).to be_truthy

      dep3 = proj.dependencies[2]
      expect(dep3).not_to be_nil
      expect(dep3[:language]).to eq(prod3[:language])
      expect(dep3[:prod_key]).to eq(prod3[:prod_key])
      expect(dep3[:version_label]).to eq('v2')
      expect(dep3[:version_requested]).to eq('0.0.0+NA')
      expect(dep3[:outdated]).to be_truthy

      dep4 = proj.dependencies[3]
      expect(dep4).not_to be_nil
      expect(dep4[:language]).to eq(prod4[:language])
      expect(dep4[:prod_key]).to eq(prod4[:prod_key])
      expect(dep4[:version_label]).to eq('master')
      expect(dep4[:version_requested]).to eq('0.0.0+NA')
      expect(dep4[:outdated]).to be_truthy

      dep5 = proj.dependencies[4]
      expect(dep5).not_to be_nil
      expect(dep5[:language]).to eq(prod5[:language])
      expect(dep5[:prod_key]).to eq(prod5[:prod_key])
      expect(dep5[:version_label]).to eq('0.8.0')
      expect(dep5[:version_requested]).to eq('0.0.0+NA')
      expect(dep5[:outdated]).to be_truthy

    end
  end

end
