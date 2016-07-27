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
      expect( deps[0].version_requested ).to eq(product1[:version])
      expect( deps[0].comperator).to eq('=')

      expect( deps[1].name ).to eq(product2[:name])
      expect( deps[1].version_requested ).to eq(product2[:version])
      expect( deps[1].comperator).to eq('=')
    end
  end
end
