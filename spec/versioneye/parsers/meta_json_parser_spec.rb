require 'spec_helper'

describe MetaJsonParser do
  let(:parser){ MetaJsonParser.new }
  let(:test_content){ File.read 'spec/fixtures/files/cpan/META.json' }

  let(:prod1){
    Product.new(
      language: Product::A_LANGUAGE_PERL,
      prod_type: Project::A_TYPE_CPAN,
      prod_key: 'perl',
      name: 'perl',
      version: '5.006'
    )
  }

  let(:prod2){
    Product.new(
      language: Product::A_LANGUAGE_PERL,
      prod_type: Project::A_TYPE_CPAN,
      prod_key: 'IO::File',
      name: 'IO::File',
      version: '5.006'
    )
  }

  let(:prod3){
    Product.new(
      language: Product::A_LANGUAGE_PERL,
      prod_type: Project::A_TYPE_CPAN,
      prod_key: 'Test::More',
      name: 'Test::More',
      version: '1.0.0'
    )
  }

  let(:prod4){
    Product.new(
      language: Product::A_LANGUAGE_PERL,
      prod_type: Project::A_TYPE_CPAN,
      prod_key: 'Test::CPAN::Meta',
      name: 'Test::Cpan::Meta',
      version: '0.13'
    )
  }

  context 'parse_dependencies' do
    it 'returns correct list of dep' do
      reqs_doc = {
        runtime: {requires: {'perl' => '1.2.3'}}
      }

      deps = parser.parse_dependencies(reqs_doc)
      expect(deps).not_to be_nil
      expect(deps.size).to eq(1)
      expect(deps[0][:name]).to eq('perl')
      expect(deps[0][:version_label]).to eq('1.2.3')
      expect(deps[0][:scope]).to eq(Dependency::A_SCOPE_RUNTIME)
    end
  end

  context 'parse_content' do
    before do
      prod1.versions << Version.new(version: '5.006')
      prod1.save

      prod2.versions << Version.new(version: '5.006')
      prod2.save

      prod3.versions << Version.new(version: '0.62')
      prod3.versions << Version.new(version: '1.0.0')
      prod3.save

      prod4.versions << Version.new(version: '0.13')
      prod4.save
    end

    it "parses the testContent correctly" do
      proj = parser.parse_content test_content
      expect(proj).not_to be_nil
      expect(proj.projectdependencies.size).to eq(4)

      dep1 = proj.projectdependencies[0]
      expect(dep1).not_to be_nil
      expect(dep1[:language]).to eq(prod1[:language])
      expect(dep1[:prod_key]).to eq(prod1[:prod_key])
      expect(dep1[:version_current]).to eq(prod1[:version])
      expect(dep1[:version_label]).to eq(prod1[:version])
      expect(dep1[:version_requested]).to eq(prod1[:version])
      expect(dep1[:comperator]).to eq('>=')
      expect(dep1[:scope]).to eq(Dependency::A_SCOPE_RUNTIME)

      dep2 = proj.projectdependencies[1]
      expect(dep2).not_to be_nil
      expect(dep2[:language]).to eq(prod2[:language])
      expect(dep2[:prod_key]).to eq(prod2[:prod_key])
      expect(dep2[:version_current]).to eq(prod2[:version])
      expect(dep2[:version_label]).to eq('>= 0')
      expect(dep2[:version_requested]).to eq(prod2[:version])
      expect(dep2[:comperator]).to eq('>=')
      expect(dep2[:scope]).to eq(Dependency::A_SCOPE_RUNTIME)

      dep3 = proj.projectdependencies[2]
      expect(dep3).not_to be_nil
      expect(dep3[:language]).to eq(prod3[:language])
      expect(dep3[:prod_key]).to eq(prod3[:prod_key])
      expect(dep3[:version_current]).to eq(prod3[:version])
      expect(dep3[:version_label]).to eq('0.62')
      expect(dep3[:version_requested]).to eq(prod3[:version])
      expect(dep3[:comperator]).to eq('>=')
      expect(dep3[:scope]).to eq(Dependency::A_SCOPE_TEST)

      dep4 = proj.projectdependencies[3]
      expect(dep4).not_to be_nil
      expect(dep4[:language]).to eq(prod4[:language])
      expect(dep4[:prod_key]).to eq(prod4[:prod_key])
      expect(dep4[:version_current]).to eq(prod4[:version])
      expect(dep4[:version_label]).to eq('0.13')
      expect(dep4[:version_requested]).to eq(prod4[:version])
      expect(dep4[:comperator]).to eq('>=')
      expect(dep4[:scope]).to eq(Dependency::A_SCOPE_TEST)


    end

  end
end
