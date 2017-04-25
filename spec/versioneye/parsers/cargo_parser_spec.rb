require 'spec_helper'

describe CargoParser do

  let(:parser){ CargoParser.new }

  let(:product1){
    Product.new(
      language: Product::A_LANGUAGE_RUST,
      prod_type: Project::A_TYPE_CRATES,
      prod_key: 'nanomsg',
      name: 'nanomsg',
      version: '0.6.2'
    )
  }

  let(:dep1){
    Projectdependency.new(
      language: Product::A_LANGUAGE_RUST,
      prod_key: 'libc',
      name: 'libc'
    )
  }

  context "parse_requested_version" do
    before do
      product1.versions << Version.new(version: '0.6.0')
      product1.versions << Version.new(version: '0.6.2')
      product1.save
    end

    it "uses latest product version if version label is empty" do
      dep = parser.parse_requested_version(nil, dep1, product1)

      expect(dep).not_to be_nil
      expect(dep[:version_requested]).to eq(product1[:version])
      expect(dep[:version_label]).to be_nil
      expect(dep[:comperator]).to eq('=')
    end

    it "parses correctly `= 0.6.0`" do
      dep = parser.parse_requested_version('= 0.6.0', dep1, product1)

      expect(dep).not_to be_nil
      expect(dep[:version_requested]).to eq('0.6.0')
      expect(dep[:version_label]).to eq('0.6.0')
      expect(dep[:comperator]).to eq('=')
    end

    it "uses the latest version when fixed version doesnt exist" do
      product1.versions.where('version': '0.6.0').delete
      product1.save

      dep = parser.parse_requested_version('= 0.6.0', dep1, product1)
      expect(dep).not_to be_nil
      expect(dep[:version_requested]).to eq(product1[:version])
      expect(dep[:version_label]).to be_nil
      expect(dep[:comperator]).to eq('=')
    end

    it "parses correctly `< 0.6.2`" do
      dep = parser.parse_requested_version('< 0.6.2', dep1, product1)

      expect(dep).not_to be_nil
      expect(dep[:version_requested]).to eq('0.6.0')
      expect(dep[:version_label]).to eq('0.6.2')
      expect(dep[:comperator]).to eq('<')
    end

    it "parses correctly `<= 0.6.2`" do
      product1.versions << Version.new(version: "0.7.0")
      product1.save

      dep = parser.parse_requested_version('<= 0.6.2', dep1, product1)

      expect(dep).not_to be_nil
      expect(dep[:version_requested]).to eq('0.6.2')
      expect(dep[:version_label]).to eq('0.6.2')
      expect(dep[:comperator]).to eq('<=')
    end

    it "parses correctly `>= 0.6.2`" do
      product1.versions << Version.new(version: '0.7.0')
      product1.save

      dep = parser.parse_requested_version('>= 0.6.2', dep1, product1)

      expect(dep).not_to be_nil
      expect(dep[:version_requested]).to eq('0.7.0')
      expect(dep[:version_label]).to eq('0.6.2')
      expect(dep[:comperator]).to eq('>=')
    end

    it "parses correctly `> 0.6.2`" do
      product1.versions << Version.new(version: '0.7.0')
      product1.save

      dep = parser.parse_requested_version('> 0.6.2', dep1, product1)

      expect(dep).not_to be_nil
      expect(dep[:version_requested]).to eq('0.7.0')
      expect(dep[:version_label]).to eq('0.6.2')
      expect(dep[:comperator]).to eq('>')
    end
  end
end
