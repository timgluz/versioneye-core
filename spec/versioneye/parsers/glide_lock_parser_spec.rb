require 'spec_helper'

describe GlideLockParser do
  let(:parser){ GlideLockParser.new }
  let(:test_content){ File.read 'spec/fixtures/files/golang/glide.lock' }

  let(:prod1){
    Product.new(
      language: Product::A_LANGUAGE_GO,
      prod_type: Project::A_TYPE_GODEP,
      prod_key:  'github.com/codegangsta/cli',
      name: 'github.com/codegangsta/cli',
      version: '1.0.0'
    )
  }

  let(:prod2){
    Product.new(
      language: Product::A_LANGUAGE_GO,
      prod_type: Project::A_TYPE_GODEP,
      prod_key:  'github.com/Masterminds/semver',
      name: 'github.com/Masterminds/semver',
      version: '1.2.0'
    )
  }

  let(:prod3){
    Product.new(
      language: Product::A_LANGUAGE_GO,
      prod_type: Project::A_TYPE_GODEP,
      prod_key:  'github.com/Masterminds/vcs',
      name: 'github.com/Masterminds/vcs',
      version: '1.3.0'
    )
  }

  let(:prod4){
    Product.new(
      language: Product::A_LANGUAGE_GO,
      prod_type: Project::A_TYPE_GODEP,
      prod_key:  'github.com/mitchellh/go-homedir',
      name: 'github.com/mitchellh/go-homedir',
      version: '1.4.0'
    )
  }

  let(:prod5){
    Product.new(
      language: Product::A_LANGUAGE_GO,
      prod_type: Project::A_TYPE_GODEP,
      prod_key:  'gopkg.in/yaml.v2',
      name: 'gopkg.in/yaml.v2',
      version: '1.5.0'
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


    it "parses correct the content of test file" do
      proj = parser.parse_content test_content
      expect(proj).not_to be_nil
      expect(proj.dependencies.size).to eq(5)

      dep1 = proj.dependencies[0]
      expect(dep1).not_to be_nil
      expect(dep1[:language]).to eq(prod1[:language])
      expect(dep1[:prod_key]).to eq(prod1[:prod_key])
      expect(dep1[:version_label]).to eq('0bdeddeeb0f650497d603c4ad7b20cfe685682f6')
      expect(dep1[:version_requested]).to eq('0.0.0+NA')
      expect(dep1[:outdated]).to be_truthy

      dep2 = proj.dependencies[1]
      expect(dep2).not_to be_nil
      expect(dep2[:language]).to eq(prod2[:language])
      expect(dep2[:prod_key]).to eq(prod2[:prod_key])
      expect(dep2[:version_label]).to eq('abff1900528dbdaf6f3f5aa92c398be1eaf2a9f7')
      expect(dep2[:version_requested]).to eq('0.0.0+NA')
      expect(dep2[:outdated]).to be_truthy

      dep3 = proj.dependencies[2]
      expect(dep3).not_to be_nil
      expect(dep3[:language]).to eq(prod3[:language])
      expect(dep3[:prod_key]).to eq(prod3[:prod_key])
      expect(dep3[:version_label]).to eq('3084677c2c188840777bff30054f2b553729d329')
      expect(dep3[:version_requested]).to eq('0.0.0+NA')
      expect(dep3[:outdated]).to be_truthy

      dep4 = proj.dependencies[3]
      expect(dep4).not_to be_nil
      expect(dep4[:language]).to eq(prod4[:language])
      expect(dep4[:prod_key]).to eq(prod4[:prod_key])
      expect(dep4[:version_label]).to eq('b8bc1bf767474819792c23f32d8286a45736f1c6')
      expect(dep4[:version_requested]).to eq('0.0.0+NA')
      expect(dep4[:outdated]).to be_truthy

      dep5 = proj.dependencies[4]
      expect(dep5).not_to be_nil
      expect(dep5[:language]).to eq(prod5[:language])
      expect(dep5[:prod_key]).to eq(prod5[:prod_key])
      expect(dep5[:version_label]).to eq('a3f3340b5840cee44f372bddb5880fcbc419b46a')
      expect(dep5[:version_requested]).to eq('0.0.0+NA')
      expect(dep5[:outdated]).to be_truthy


    end
  end
end
