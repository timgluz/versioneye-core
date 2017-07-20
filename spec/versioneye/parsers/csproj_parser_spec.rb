require 'spec_helper'

describe 'CsprojParser' do
  let(:parser){ CsprojParser.new }
  let(:test_content){ File.read('spec/fixtures/files/nuget/test.csproj') }

  let(:product1){
    Product.new(
      language: Product::A_LANGUAGE_CSHARP,
      prod_type: Project::A_TYPE_NUGET,
      prod_key: 'Microsoft.EntityFrameworkCore',
      name: 'Microsoft.EntityFrameworkCore',
      version: '1.6.5'
    )
  }

  let(:product2){
    Product.new(
      language: Product::A_LANGUAGE_CSHARP,
      prod_type: Project::A_TYPE_NUGET,
      prod_key: 'Microsoft.NETCore.App',
      name: 'Microsoft.NETCore.App',
      version: '2.0.0'
    )
  }

  let(:product3){
     Product.new(
      language: Product::A_LANGUAGE_CSHARP,
      prod_type: Project::A_TYPE_NUGET,
      prod_key: 'System.Collections.Immutable',
      name: 'System.Collections.Immutable',
      version: '1.3.1'
    )

  }

  context "parse_dependencies" do

    it "extracts correct list of dependencies from the test file" do
      xml_doc = parser.fetch_xml test_content
      expect(xml_doc).not_to be_nil

      deps = parser.parse_dependencies(xml_doc)
      expect(deps.size).to eq(3)

      expect(deps[0][:language]).to eq(product1[:language])
      expect(deps[0][:prod_key]).to eq(product1[:prod_key])
      expect(deps[0][:name]).to eq(product1[:name])
      expect(deps[0][:version_label]).to eq('[1.3.2,1.5)')

      expect(deps[1][:language]).to eq(product3[:language])
      expect(deps[1][:prod_key]).to eq(product3[:prod_key])
      expect(deps[1][:name]).to eq(product3[:name])
      expect(deps[1][:version_label]).to eq('[1.3.1]')

      expect(deps[2][:language]).to eq(product2[:language])
      expect(deps[2][:prod_key]).to eq(product2[:prod_key])
      expect(deps[2][:name]).to eq(product2[:name])
      expect(deps[2][:version_label]).to eq('[1.1.0]')

    end
  end

  context "parse_content" do
    before do
      product1.versions << Version.new(version: '1.3.0')
      product1.versions << Version.new(version: '1.4.0')
      product1.versions << Version.new(version: '1.6.5')
      product1.save

      product2.versions << Version.new(version: '1.1.0')
      product2.save

      product3.versions << Version.new(version: '1.1.37')
      product3.versions << Version.new(version: '1.2.0')
      product3.versions << Version.new(version: '1.3.0-preview1-24530-04 ')
      product3.versions << Version.new(version: '1.3.1')
      product3.save
    end

    it "parses test file correctly" do
      proj = parser.parse_content test_content
      expect(proj).not_to be_nil
      expect(proj.dependencies.size).to eq(3)

      dep1 = proj.dependencies[0]
      expect(dep1[:name]).to eq(product1[:name])
      expect(dep1[:prod_key]).to eq(product1[:prod_key])
      expect(dep1[:language]).to eq(product1[:language])
      expect(dep1[:scope]).to eq(Dependency::A_SCOPE_COMPILE)
      expect(dep1[:version_requested]).to eq('1.4.0')
      expect(dep1[:version_label]).to eq('[1.3.2,1.5)')
      expect(dep1[:comperator]).to eq('>=x<')
      expect(dep1[:outdated]).to be_truthy

      dep2 = proj.dependencies[1]
      expect(dep2[:name]).to eq(product3[:name])
      expect(dep2[:prod_key]).to eq(product3[:prod_key])
      expect(dep2[:language]).to eq(product3[:language])
      expect(dep2[:scope]).to eq(Dependency::A_SCOPE_COMPILE)
      expect(dep2[:version_requested]).to eq('1.3.1')
      expect(dep2[:version_label]).to eq('[1.3.1]')
      expect(dep2[:comperator]).to eq('=')
      expect(dep2[:outdated]).to be_falsey

      dep3 = proj.dependencies[2]
      expect(dep3[:name]).to eq(product2[:name])
      expect(dep3[:prod_key]).to eq(product2[:prod_key])
      expect(dep3[:language]).to eq(product2[:language])
      expect(dep3[:scope]).to eq(Dependency::A_SCOPE_COMPILE)
      expect(dep3[:version_requested]).to eq('1.1.0')
      expect(dep3[:version_label]).to eq('[1.1.0]')
      expect(dep3[:comperator]).to eq('=')
      expect(dep3[:outdated]).to be_falsey


    end
  end
end
