require 'spec_helper'

describe NugetPackagesParser do
  let(:test_file_url){
    "https://s3.amazonaws.com/veye_test_env/nuget/packages.config"
  }

  let(:parser){ NugetPackagesParser.new  }
  let(:product1){
    FactoryGirl.create(
      :product_with_versions,
      prod_key: 'NUnit',
      name: 'NUnit',
      prod_type: Project::A_TYPE_NUGET,
      language: Product::A_LANGUAGE_CSHARP,
      version: "2.5.10.11092"
    )
  }
  let(:product2){
    FactoryGirl.create(
      :product_with_versions,
      prod_key: 'Moq',
      name: 'Moq',
      prod_type: Project::A_TYPE_NUGET,
      language: Product::A_LANGUAGE_CSHARP,
      version: "4.0.10827"
    )
  }

  context "parse" do
    it "fetches file properly" do
      project = parser.parse(test_file_url)
      expect( project ).not_to be_nil
    end

    it "parses packages.config correctly" do
      project = parser.parse(test_file_url)
      expect( project ).not_to be_nil
      expect( project.projectdependencies.size ).to eq(2)

      deps = project.projectdependencies
      
      expect( deps[0].name ).to eq(product1[:name])
      expect( deps[0].version_requested ).to eq( product1[:version] )
      expect( deps[0].comperator).to eq('=')

      expect( deps[1].name ).to eq(product2[:name])
      expect( deps[1].version_requested ).to eq( product2[:version] )
      expect( deps[1].comperator).to eq('=')
    end
  end

  let(:onwerk_file){ File.read "spec/fixtures/files/nuget/onwerk_packages.config" }
  let(:product3){
    FactoryGirl.create(
      :product_with_versions,
      prod_key: 'CsQuery',
      name: 'CsQuery',
      prod_type: Project::A_TYPE_NUGET,
      language: Product::A_LANGUAGE_CSHARP,
      version: '1.3.4'
    )
  }
  let(:product4){
    FactoryGirl.create(
      :product_with_versions,
      prod_key: 'BuildTools.StyleCop',
      name: 'BuildTools.StyleCop',
      prod_type: Project::A_TYPE_NUGET,
      language: Product::A_LANGUAGE_CSHARP,
      version: '4.7.49.0'
    )
  }
  let(:product5){
    FactoryGirl.create(
      :product_with_versions,
      prod_key: 'Microsoft.AspNet.Razor',
      name: 'Microsoft.AspNet.Razor',
      prod_type: Project::A_TYPE_NUGET,
      language: Product::A_LANGUAGE_CSHARP,
      version: '2.0.30506.0'
    )
  }
  let(:product6){
    FactoryGirl.build(
      :product_with_versions,
      prod_key: 'Onwerk.Mailer',
      name: 'Onwerk.Mailer',
      prod_type: Project::A_TYPE_NUGET,
      language: Product::A_LANGUAGE_CSHARP,
      version: '1.6.6.0'
    )
  }
  let(:product7){
    FactoryGirl.create(
      :product_with_versions,
      prod_key: 'Simple.Data.Ado',
      name: 'Simple.Data.Ado',
      prod_type: Project::A_TYPE_NUGET,
      language: Product::A_LANGUAGE_CSHARP,
      version: '0.18.3.1'
    )
  }

  context "onwerk's failed project" do
    it "parses their packages.config correctly" do
      product3.versions << FactoryGirl.build(:product_version, version: '1.3.4')
      product3.versions << FactoryGirl.build(:product_version, version: '1.4.0')

      product7.versions << FactoryGirl.build(:product_version, version: '0.18.2')
      product7.versions << FactoryGirl.build(:product_version, version: '0.18.3.1')
      
      
      project = parser.parse_content(onwerk_file, "ftp://spec_test")
      expect(project).not_to be_nil
      expect(project.projectdependencies.size).to eq(5)

      deps = project.projectdependencies

      expect( deps[0].name ).to eq(product3[:name])
      expect( deps[0].version_label ).to eq('[1.3.4]')
      expect( deps[0].version_requested ).to eq(product3[:version])
      expect( deps[0].comperator).to eq('=')

      expect( deps[1].name ).to eq(product4[:name])
      expect( deps[1].version_requested ).to eq(product4[:version])
      expect( deps[1].comperator).to eq('=')

      expect( deps[2].name ).to eq(product5[:name])
      expect( deps[2].version_requested ).to eq(product5[:version])
      expect( deps[2].comperator).to eq('=')

      expect( deps[3].name ).to eq(product6[:name])
      expect( deps[3].version_requested ).to eq(product6[:version])
      expect( deps[3].comperator).to eq('=')

      expect( deps[4].name ).to eq(product7[:name])
      expect( deps[4].version_requested ).to eq(product7[:version])
      expect( deps[4].comperator).to eq('=')
    end
  end

  let(:issue58_file){File.read("spec/fixtures/files/nuget/packages_issue58.config")}
  let(:product8){
    FactoryGirl.build(
      :product_with_versions,
      name:     'Newtonsoft.Json',
      prod_key: 'Newtonsoft.Json',
      prod_type: Project::A_TYPE_NUGET,
      language: Product::A_LANGUAGE_CSHARP,
      version: '9.0.1'
    )
  }

  let(:product9){
    FactoryGirl.build(
      :product_with_versions,
      name:     'xunit',
      prod_key: 'xunit',
      prod_type: Project::A_TYPE_NUGET,
      language: Product::A_LANGUAGE_CSHARP,
      version: '2.1.0'
    )
  }

  let(:product10){
    FactoryGirl.build(
      :product_with_versions,
      name: 'xunit.runner.visualstudio',
      prod_key: 'xunit.runner.visualstudio',
      prod_type: Project::A_TYPE_NUGET,
      language: Product::A_LANGUAGE_CSHARP,
      version: '2.1.0'
    )
  }

  context "issue58 fails to parse versions with build infos" do

    it "fixes issue with exact match" do
      product8.versions << FactoryGirl.build(:product_version, version: '9.0.1')

      product9.versions << FactoryGirl.build(:product_version, version: '2.1.0')
      product9.versions << FactoryGirl.build(:product_version, version: '2.2.0-beta1-build3239')
      product9.versions << FactoryGirl.build(:product_version, version: '2.2.0-beta3-build3402')
      product9.versions << FactoryGirl.build(:product_version, version: '2.2.0-beta5-build3474')

      product9.save

      product10.versions << FactoryGirl.build(:product_version, version: '2.1.0')
      product10.versions << FactoryGirl.build(:product_version, version: '2.2.0-beta3-build1182')
      product10.versions << FactoryGirl.build(:product_version, version: '2.2.0-beta3-build1187')
      product10.versions << FactoryGirl.build(:product_version, version: '2.2.0-beta5-build1225')
      product10.save

      project = parser.parse_content(issue58_file, "ftp://spec_test")
      expect(project).not_to be_nil
      expect(project.projectdependencies.size).to eq(3)

      deps = project.projectdependencies
      
      expect( deps[0].name ).to eq(product8[:name])
      expect( deps[0].version_requested ).to eq(product8[:version])
      expect( deps[0].version_label ).to eq('[9.0.1]')
      expect( deps[0].comperator).to eq('=')

      expect( deps[1].name ).to eq(product9[:name])
      expect( deps[1].version_requested ).to eq('2.2.0-beta3-build3402')
      expect( deps[1].version_label ).to eq('[2.2.0-beta3-build3402]')
      expect( deps[1].comperator).to eq('=')

      expect( deps[2].name ).to eq(product10[:name])
      expect( deps[2].version_requested ).to eq('2.2.0-beta3-build1187')
      expect( deps[2].version_label ).to eq('[2.2.0-beta3-build1187]')
      expect( deps[2].comperator).to eq('=')

    end
  end
end
