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
      project.should_not be_nil
    end

    it "parses project json file correctly" do
      project = parser.parse(test_file_url)
      project.should_not be_nil

      project.projectdependencies.size.should eq(6)
      deps = project.projectdependencies
      
      deps[0].name.should eq(product4[:name])
      deps[0].version_requested.should eq(product4[:version])
      deps[0].comperator.should eq("=")

      deps[1].name.should eq(product5[:name])
      deps[1].version_requested.should eq(product5[:version])
      deps[1].comperator.should eq("=")

      deps[2].name.should eq(product6[:name])
      deps[2].version_requested.should eq(product6[:version])
      deps[2].comperator.should eq("=")

      deps[3].name.should eq(product7[:name])
      deps[3].version_requested.should eq(product7[:version])
      deps[3].comperator.should eq("=")

      deps[4].name.should eq(product8[:name])
      deps[4].version_requested.should eq(product8[:version])
      deps[4].comperator.should eq("=")

      deps[5].name.should eq(product9[:name])
      deps[5].version_requested.should eq(product9[:version])
      deps[5].comperator.should eq("=")

    end
  end

end
