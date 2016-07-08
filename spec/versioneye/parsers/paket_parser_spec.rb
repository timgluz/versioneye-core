require 'spec_helper'

describe PaketParser do
  let(:test_file_url){
    "spec/fixtures/files/nuget/paket.dependencies"
  }

  let(:prod1){
    FactoryGirl.create(
      :product_with_versions,
      prod_key: 'NUnit',
      name: 'NUnit',
      prod_type: Project::A_TYPE_NUGET,
      language: Product::A_LANGUAGE_CSHARP,
      version: '2.7'
    )
  }

  let(:parser){NugetParser.new}

  context "parser rules" do
    it "matches version numbers" do
      version = parser.rules[:version]
      "1".match(version).should_not be_nil
      "1.0".match(version).should_not be_nil
      "1.1.0".match(version).should_not be_nil
      "  1.1.0".match(version).should_not be_nil
      "1.1.0  ".match(version).should_not be_nil
      "  1.1.0  ".match(version).should_not be_nil
    end

    it "matches semantic versions" do
      semver = parser.rules[:semver]
      "1.0-alpha".match(semver).should_not be_nil
      "1.0-alpha.1".match(semver).should_not be_nil
      "1.0-alpha-1.0".match(semver).should_not be_nil
      "1.0+build".match(semver).should_not be_nil
      "1.0+build.1".match(semver).should_not be_nil
      "1.0-alpha+build".match(semver).should_not be_nil
      "1.0-alpha.1.2+build.2".match(semver).should_not be_nil
    end
  end
end
