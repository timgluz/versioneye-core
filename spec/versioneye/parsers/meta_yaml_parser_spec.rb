require 'spec_helper'

describe MetaYamlParser do
  let(:parser){ MetaYamlParser.new }
  let(:test_content){ File.read 'spec/fixtures/files/cpan/META.yml' }

  let(:prod1){
    Product.new(
      language: Product::A_LANGUAGE_PERL,
      prod_type: Project::A_TYPE_CPAN,
      prod_key: 'Digest::HMAC_SHA1',
      name: 'Digest::HMAC_SHA1',
      version: '1.0.0'
    )
  }

  let(:prod2){
    Product.new(
      language: Product::A_LANGUAGE_PERL,
      prod_type: Project::A_TYPE_CPAN,
      prod_key: 'IO::Socket::INET',
      name: 'IO::Socket::INET',
      version: '2.0.0'
    )
  }

  let(:prod3){
    Product.new(
      language: Product::A_LANGUAGE_PERL,
      prod_type: Project::A_TYPE_CPAN,
      prod_key: 'Test::More',
      name: 'Test::More',
      version: '0.1'
    )
  }

  let(:prod4){
    Product.new(
      language: Product::A_LANGUAGE_PERL,
      prod_type: Project::A_TYPE_CPAN,
      prod_key: 'ExtUtils::MakeMaker',
      name: 'ExtUtils::MakeMaker',
      version: '3.0.0'
    )
  }

  let(:prod5){
    Product.new(
      language: Product::A_LANGUAGE_PERL,
      prod_type: Project::A_TYPE_CPAN,
      prod_key: 'Cpanel::JSON::XS',
      name: 'Cpanel::JSON::XS',
      version: '5.0.0'
    )
  }

  context 'parse_content' do
    before do
      prod1.versions << Version.new(version: '1.0.0')
      prod1.save

      prod2.versions << Version.new(version: '2.0.0')
      prod2.save

      prod3.versions << Version.new(version: '0.1')
      prod3.save

      prod4.versions << Version.new(version: '3.0.0')
      prod4.save

      prod5.versions << Version.new(version: '5.0.0')
      prod5.save
    end

    it "parses test file correctly" do
      proj = parser.parse_content test_content
      expect(proj).not_to be_nil
      expect(proj.projectdependencies.size).to eq(5)

      dep1 = proj.projectdependencies[0]
      expect(dep1[:language]).to eq(prod1[:language])
      expect(dep1[:prod_key]).to eq(prod1[:prod_key])
      expect(dep1[:version_current]).to eq(prod1[:version])
      expect(dep1[:version_label]).to eq('1.0.0')
      expect(dep1[:version_requested]).to eq('1.0.0')
      expect(dep1[:comperator]).to eq('>=')
      expect(dep1[:outdated]).to be_falsey

      dep2 = proj.projectdependencies[1]
      expect(dep2[:language]).to eq(prod2[:language])
      expect(dep2[:prod_key]).to eq(prod2[:prod_key])
      expect(dep2[:version_current]).to eq(prod2[:version])
      expect(dep2[:version_label]).to eq('2.0.0')
      expect(dep2[:version_requested]).to eq('2.0.0')
      expect(dep2[:comperator]).to eq('>=')
      expect(dep2[:outdated]).to be_falsey

      dep3 = proj.projectdependencies[2]
      expect(dep3[:language]).to eq(prod3[:language])
      expect(dep3[:prod_key]).to eq(prod3[:prod_key])
      expect(dep3[:version_current]).to eq(prod3[:version])
      expect(dep3[:version_label]).to eq('0.1')
      expect(dep3[:version_requested]).to eq('0.1')
      expect(dep3[:comperator]).to eq('>=')
      expect(dep3[:outdated]).to be_falsey

      dep4 = proj.projectdependencies[3]
      expect(dep4[:language]).to eq(prod4[:language])
      expect(dep4[:prod_key]).to eq(prod4[:prod_key])
      expect(dep4[:version_current]).to eq(prod4[:version])
      expect(dep4[:version_label]).to eq('>= 0')
      expect(dep4[:version_requested]).to eq('3.0.0')
      expect(dep4[:comperator]).to eq('>=')
      expect(dep4[:outdated]).to be_falsey

      dep5 = proj.projectdependencies[4]
      expect(dep5[:language]).to eq(prod5[:language])
      expect(dep5[:prod_key]).to eq(prod5[:prod_key])
      expect(dep5[:version_current]).to eq(prod5[:version])
      expect(dep5[:version_label]).to eq('>= 0')
      expect(dep5[:version_requested]).to eq('5.0.0')
      expect(dep5[:comperator]).to eq('>=')
      expect(dep5[:outdated]).to be_falsey


    end
  end
end
