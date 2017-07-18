require 'spec_helper'

describe GemfileParser do
  let(:auth_token){ Settings.instance.github_client_secret }
  let(:test_content){ File.read 'spec/fixtures/files/rubygem/Gemfile_gh' }
  let(:parser){ GemfileParser.new }

  let(:prod1){
    Product.new(
      language: Product::A_LANGUAGE_RUBY,
      prod_type: Project::A_TYPE_RUBYGEMS,
      prod_key: 'rails',
      name: 'rails',
      version: '5.1.2'
    )
  }

  let(:prod2){
    Product.new(
      language: Product::A_LANGUAGE_RUBY,
      prod_type: Project::A_TYPE_RUBYGEMS,
      prod_key: 'rspec',
      name: 'rspec',
      version: '3.1.6'
    )
  }

  let(:prod3){
    Product.new(
      language: Product::A_LANGUAGE_RUBY,
      prod_type: Project::A_TYPE_RUBYGEMS,
      prod_key: 'devise',
      name: 'devise',
      version: '4.3.0'
    )
  }

  let(:prod4){
    Product.new(
      language: Product::A_LANGUAGE_RUBY,
      prod_type: Project::A_TYPE_RUBYGEMS,
      prod_key: 'sass',
      name: 'sass',
      version: '3.4.21'
    )
  }

  context "parse_content with Github dependencies" do
    before do
      prod1.versions << Version.new(version: '5.1.2', released_at: DateTime.parse('2017-06-26'))
      prod1.save

      prod2.versions << Version.new(version: '3.1.6', released_at: DateTime.now)
      prod2.save

      prod3.versions << Version.new(version: '4.3.0', released_at: DateTime.parse('2017-05-15'))
      prod3.save

      prod4.versions << Version.new(version: '3.4.21', released_at: DateTime.parse('2016-01-12'))
      prod4.save
    end

    it "parses and marks outdated packages correctly" do
      VCR.use_cassette('github/gemfile_parsers/check_gemfile_deps') do
        proj = parser.parse_content(test_content, auth_token)
        expect(proj).not_to be_nil
        expect(proj.dependencies.size).to eq(4)

        dep1 = proj.dependencies[0]
        expect(dep1[:language]).to eq(prod1[:language])
        expect(dep1[:prod_key]).to eq(prod1[:prod_key])
        expect(dep1[:version_requested]).to eq('GITHUB')
        expect(dep1[:version_label]).to eq('git:https://github.com/rails/rails.git#f8f3d70')
        expect(dep1[:repo_fullname]).to eq('rails/rails')
        expect(dep1[:repo_ref]).to eq('f8f3d70')
        expect(dep1[:outdated]).to be_falsey

        dep2 = proj.dependencies[1]
        expect(dep2[:language]).to eq(prod2[:language])
        expect(dep2[:prod_key]).to eq(prod2[:prod_key])
        expect(dep2[:version_requested]).to eq('GITHUB')
        expect(dep2[:version_label]).to eq('git:git@github.com:rspec/rspec.git#2-0-stable')
        expect(dep2[:repo_fullname]).to eq('rspec/rspec')
        expect(dep2[:repo_ref]).to eq('2-0-stable')
        expect(dep2[:outdated]).to be_truthy

        dep3 = proj.dependencies[2]
        expect(dep3[:language]).to eq(prod3[:language])
        expect(dep3[:prod_key]).to eq(prod3[:prod_key])
        expect(dep3[:version_requested]).to eq('GITHUB')
        expect(dep3[:version_label]).to eq('git:git@github.com:plataformatec/devise#v4.3.0')
        expect(dep3[:repo_fullname]).to eq('plataformatec/devise')
        expect(dep3[:repo_ref]).to eq('v4.3.0')
        expect(dep3[:outdated]).to be_falsey

        dep4 = proj.dependencies[3]
        expect(dep4[:language]).to eq(prod4[:language])
        expect(dep4[:prod_key]).to eq(prod4[:prod_key])
        expect(dep4[:version_requested]).to eq('GITHUB')
        expect(dep4[:version_label]).to eq('github:sass/sass#3.4.21')
        expect(dep4[:repo_fullname]).to eq('sass/sass')
        expect(dep4[:repo_ref]).to eq('3.4.21')
        expect(dep4[:outdated]).to be_falsey


      end
    end
  end
end
