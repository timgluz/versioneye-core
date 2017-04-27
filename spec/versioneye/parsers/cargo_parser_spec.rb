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

  context "is_semver" do
    it "returns truthy for version without selectors" do
      expect( parser.is_semver('1') ).to be_truthy
      expect( parser.is_semver('1.2')).to be_truthy
      expect( parser.is_semver('1.2.3')).to be_truthy
    end

    it "returns falsey for version with selectors" do
      expect( parser.is_semver('>1')).to be_falsey
      expect( parser.is_semver('*')).to be_falsey
      expect( parser.is_semver('^ 1.0.0')).to be_falsey
    end
  end

  context "caret_lower_border" do
    it "returns correct semver strings" do
      expect( parser.caret_lower_border("1.2.3")).to eq('1.2.3')
      expect( parser.caret_lower_border("1.2.3-alpha")).to eq('1.2.3')
      expect( parser.caret_lower_border("1.2.3-beta")).to eq('1.2.3')

      expect( parser.caret_lower_border('1.2') ).to eq('1.2.0')
      expect( parser.caret_lower_border('0.2.3') ).to eq('0.2.3')
      expect( parser.caret_lower_border('0.0.3') ).to eq('0.0.3')
      expect( parser.caret_lower_border('0.0')).to eq('0.0.0')
      expect( parser.caret_lower_border('0')).to eq('0.0.0')
    end
  end

  context "caret_upper_border" do
    it "returns correct upper lever semver" do
      expect( parser.caret_upper_border('1.2.3') ).to eq('2.0.0')
      expect( parser.caret_upper_border('1.2') ).to eq('2.0.0')
      expect( parser.caret_upper_border('1') ).to eq('2.0.0')
      expect( parser.caret_upper_border('0.2.3')).to eq('0.3.0')
      expect( parser.caret_upper_border('0.0.3')).to eq('0.0.4')
      expect( parser.caret_upper_border('0.0.0')).to eq('1.0.0')
    end
  end

  context "tilde_lower_border" do
    it "returns correct lower border" do
      expect( parser.tilde_lower_border('1.2.3')).to eq('1.2.3')
      expect( parser.tilde_lower_border('1.2')).to eq('1.2.0')
      expect( parser.tilde_lower_border('1')).to eq('1.0.0')
    end
  end

  context "tilde_upper_border" do
    it "returns correct upper version" do
      expect( parser.tilde_upper_border('1.2.3')).to eq('1.3.0')
      expect( parser.tilde_upper_border('1.2')).to eq('1.3.0')
      expect( parser.tilde_upper_border('1.0')).to eq('1.1.0')
      expect( parser.tilde_upper_border('1')).to eq('2.0.0')
      expect( parser.tilde_upper_border('0')).to eq('1.0.0')
    end
  end

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
      expect(dep[:version_label]).to eq('')
      expect(dep[:comperator]).to eq('=')
    end

    it "uses latest product version if version label is *, x, X" do
      dep = parser.parse_requested_version("*", dep1, product1)

      expect(dep).not_to be_nil
      expect(dep[:version_requested]).to eq(product1[:version])
      expect(dep[:version_label]).to eq('*')
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

    it "parses correctly caret selectors" do
      product1.versions << Version.new(version: '0.7.0')
      product1.versions << Version.new(version: '1.0.0')
      product1.save

      dep = parser.parse_requested_version '^0.6', dep1, product1
      expect(dep).not_to be_nil
      expect(dep[:version_requested]).to eq('0.6.2')
      expect(dep[:version_label]).to eq('0.6')
      expect(dep[:comperator]).to eq('^')

      dep = parser.parse_requested_version '^0', dep1, product1
      expect(dep).not_to be_nil
      expect(dep[:version_requested]).to eq('0.7.0')
      expect(dep[:version_label]).to eq('0')
      expect(dep[:comperator]).to eq('^')

      #NB! versions without any specifiers are classified as caret selector
      dep = parser.parse_requested_version '0.6', dep1, product1
      expect(dep).not_to be_nil
      expect(dep[:version_requested]).to eq('0.6.2')
      expect(dep[:version_label]).to eq('0.6')
      expect(dep[:comperator]).to eq('^')
    end

    it "parses correctly tilde specifiers" do
      product1.versions << Version.new(version: '0.7.0')
      product1.versions << Version.new(version: '1.0.0')
      product1.save

      dep = parser.parse_requested_version '~0.6', dep1, product1
      expect(dep).not_to be_nil
      expect(dep[:version_requested]).to eq('0.6.2')
      expect(dep[:version_label]).to eq('0.6')
      expect(dep[:comperator]).to eq('~')

      dep = parser.parse_requested_version '~0', dep1, product1
      expect(dep).not_to be_nil
      expect(dep[:version_requested]).to eq('0.7.0')
      expect(dep[:version_label]).to eq('0')
      expect(dep[:comperator]).to eq('~')
    end

    it "parses correctly wildcard selectors" do
      product1.versions << Version.new(version: '0.7.0')
      product1.versions << Version.new(version: '1.0.0')
      product1.save

      dep = parser.parse_requested_version '0.6.*', dep1, product1
      expect(dep).not_to be_nil
      expect(dep[:version_requested]).to eq('0.6.2')
      expect(dep[:version_label]).to eq('0.6.*')
      expect(dep[:comperator]).to eq('*')

      dep = parser.parse_requested_version '0.*', dep1, product1
      expect(dep).not_to be_nil
      expect(dep[:version_requested]).to eq('0.7.0')
      expect(dep[:version_label]).to eq('0.*')
      expect(dep[:comperator]).to eq('*')

      dep = parser.parse_requested_version '1.*', dep1, product1
      expect(dep).not_to be_nil
      expect(dep[:version_requested]).to eq('1.0.0')
      expect(dep[:version_label]).to eq('1.*')
      expect(dep[:comperator]).to eq('*')
    end
  end
end
