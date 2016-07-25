require 'spec_helper'

describe NugetJsonParser do
  let(:test_file_url){
    "https://s3.amazonaws.com/veye_test_env/nuget/project.json"
  }

  let(:product4){
    FactoryGirl.create(
      :product_with_versions,
      prod_key: "Microsoft.CodeAnalysis.CSharp.Workspaces",
      name: "Microsoft.CodeAnalysis.CSharp.Workspaces",
      prod_type: Project::A_TYPE_NUGET,
      language: Product::A_LANGUAGE_CSHARP,
      version: "1.0.0"
    )
  }
  let(:product5){
    FactoryGirl.create(
      :product_with_versions,
      prod_key: "Microsoft.Composition",
      name: "Microsoft.Composition",
      prod_type: Project::A_TYPE_NUGET,
      language: Product::A_LANGUAGE_CSHARP,
      version: "1.0.30"
    )
  }
  let(:product6){
    FactoryGirl.create(
      :product_with_versions,
      prod_key: "Microsoft.Dnx.Runtime",
      name: "Microsoft.Dnx.Runtime",
      prod_type: Project::A_TYPE_NUGET,
      language: Product::A_LANGUAGE_CSHARP,
      version: "1.0.0-rc1-final"
    )
  }
  let(:product7){
    FactoryGirl.create(
      :product_with_versions,
      prod_key: "Microsoft.Dnx.Compilation",
      name: "Microsoft.Dnx.Compilation",
      prod_type: Project::A_TYPE_NUGET,
      language: Product::A_LANGUAGE_CSHARP,
      version: "1.0.0-rc1-final"
    )
  }
  let(:product8){
    FactoryGirl.create(
      :product_with_versions,
      prod_key: "Microsoft.Dnx.Compilation.CSharp",
      name: "Microsoft.Dnx.Compilation.CSharp",
      prod_type: Project::A_TYPE_NUGET,
      language: Product::A_LANGUAGE_CSHARP,
      version: "1.0.0-rc1-final"
    )
  }

  let(:product9){
    FactoryGirl.create(
      :product_with_versions,
      prod_key: "Microsoft.Dnx.Compilation.CSharp.Common",
      name:"Microsoft.Dnx.Compilation.CSharp.Common", 
      prod_type: Project::A_TYPE_NUGET,
      language: Product::A_LANGUAGE_CSHARP,
      version: "1.0.0-rc1-final"
    )
  }

  let(:parser){ NugetJsonParser.new }

  context "parse" do
    it "fetches file properly" do
      project = parser.parse(test_file_url)
      expect( project ).not_to be_nil
    end

    it "parses project json file correctly" do
      project = parser.parse(test_file_url)
      expect( project ).not_to be_nil

      expect( project.projectdependencies.size ).to eq(6)
      deps = project.projectdependencies
      
      expect( deps[0].name ).to eq(product4[:name])
      expect( deps[0].version_requested ).to eq(product4[:version])
      expect( deps[0].comperator ).to eq("=")

      expect( deps[1].name ).to eq(product5[:name])
      expect( deps[1].version_requested ).to eq(product5[:version])
      expect( deps[1].comperator ).to eq("=")

      expect( deps[2].name ).to eq(product6[:name])
      expect( deps[2].version_requested ).to eq(product6[:version])
      expect( deps[2].comperator ).to eq("=")

      expect( deps[3].name ).to eq(product7[:name])
      expect( deps[3].version_requested ).to eq(product7[:version])
      expect( deps[3].comperator ).to eq("=")

      expect( deps[4].name ).to eq(product8[:name])
      expect( deps[4].version_requested ).to eq(product8[:version])
      expect( deps[4].comperator ).to eq("=")

      expect( deps[5].name ).to eq(product9[:name])
      expect( deps[5].version_requested ).to eq(product9[:version])
      expect( deps[5].comperator ).to eq("=")

    end

    it "parses project even when some product has no matching versions" do
      product4.versions.delete_all
      product5.versions.delete_all

      project = parser.parse(test_file_url)
      expect( project ).not_to be_nil

      expect( project.projectdependencies.size ).to eq(6)
      deps = project.projectdependencies
 
      expect( deps[0].name ).to eq(product4[:name])
      expect( deps[0].version_requested ).to eq(product4[:version])
      expect( deps[0].comperator ).to eq(">=")

      expect( deps[1].name ).to eq(product5[:name])
      expect( deps[1].version_requested ).to eq(product5[:version])
      expect( deps[1].comperator ).to eq(">=")

      expect( deps[2].name ).to eq(product6[:name])
      expect( deps[2].version_requested ).to eq(product6[:version])
      expect( deps[2].comperator ).to eq("=")

      
    end
  end

end
