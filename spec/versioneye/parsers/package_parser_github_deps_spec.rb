require 'spec_helper'

describe PackageParser do
  let(:auth_token){ Settings.instance.github_client_secret }

  let(:parser){ PackageParser.new }
  let(:test_content){ File.read 'spec/fixtures/files/npm/package_github_deps.json'  }

  let(:prod1){
    Product.new(
      language: Product::A_LANGUAGE_NODEJS,
      prod_type: Project::A_TYPE_NPM,
      prod_key: 'express',
      name: 'express',
      version: '4.15.3'
    )
  }

  let(:prod2){
    Product.new(
      language: Product::A_LANGUAGE_NODEJS,
      prod_type: Project::A_TYPE_NPM,
      prod_key: 'mocha',
      name: 'mocha',
      version: '3.4.2'
    )
  }

  let(:prod3){
    Product.new(
      language: Product::A_LANGUAGE_NODEJS,
      prod_type: Project::A_TYPE_NPM,
      prod_key: 'chai',
      name: 'chai',
      version: '4.0.2'
    )
  }

  context "parse_content with Github dependencies" do
    before do
      prod1.versions << Version.new(version: '4.15.3', released_at: DateTime.parse('2017-05-12'))
      prod1.save

      prod2.versions << Version.new(version: '3.4.2', released_at: DateTime.now)
      prod2.save

      prod3.versions << Version.new(version: '4.0.2', released_at: DateTime.parse('2017-05-04'))
      prod3.save
    end

    it "parses and marks outdated packages correctly" do
      VCR.use_cassette('github/package_parsers/check_deps') do
        proj = parser.parse_content(test_content, auth_token)
        expect(proj).not_to be_nil
        expect(proj.dependencies.size).to eq(3)

        dep1 = proj.dependencies[0]
        expect(dep1[:language]).to eq(prod1[:language])
        expect(dep1[:prod_key]).to eq(prod1[:prod_key])
        expect(dep1[:version_requested]).to eq('GITHUB')
        expect(dep1[:version_label]).to eq('expressjs/express')
        expect(dep1[:repo_fullname]).to eq('expressjs/express')
        expect(dep1[:repo_ref]).to eq('master')
        expect(dep1[:outdated]).to be_falsey

        dep2 = proj.dependencies[1]
        expect(dep2[:language]).to eq(prod2[:language])
        expect(dep2[:prod_key]).to eq(prod2[:prod_key])
        expect(dep2[:version_requested]).to eq('GITHUB')
        expect(dep2[:version_label]).to eq('mochajs/mocha#4727d357ea')
        expect(dep2[:repo_fullname]).to eq('mochajs/mocha')
        expect(dep2[:repo_ref]).to eq('4727d357ea')
        expect(dep2[:outdated]).to be_truthy

        dep3 = proj.dependencies[2]
        expect(dep3[:language]).to eq(prod3[:language])
        expect(dep3[:prod_key]).to eq(prod3[:prod_key])
        expect(dep3[:version_requested]).to eq('GITHUB')
        expect(dep3[:version_label]).to eq('chaijs/chai#master')
        expect(dep3[:repo_fullname]).to eq('chaijs/chai')
        expect(dep3[:repo_ref]).to eq('master')
        expect(dep3[:outdated]).to be_falsey

      end
    end
  end

end
