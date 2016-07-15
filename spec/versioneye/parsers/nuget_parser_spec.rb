require 'spec_helper'

describe NugetParser do
  let(:test_file_url){
    "https://s3.amazonaws.com/veye_test_env/nuget/Microsoft.AspNet.SignalR.Client.nuspec" 
  }
  let(:product1){
    FactoryGirl.create(
      :product_with_versions,
      prod_key: "Newtonsoft.Json",
      name: "Newtonsoft.Json",
      prod_type: Project::A_TYPE_NUGET,
      language: Product::A_LANGUAGE_CSHARP,
      version: "5.0.0"
    )
  }
  let(:product2){
    FactoryGirl.create(
      :product_with_versions,
      prod_key: "Microsoft.Net.Http",
      name: "Microsoft.Net.Http",
      prod_type: Project::A_TYPE_NUGET,
      language: Product::A_LANGUAGE_CSHARP,
      version: "2.1.10"
    )
  }
  let(:product3){
    FactoryGirl.create(
      :product_with_versions,
      prod_key: "Newton.Json",
      name: "Newton.Json",
      prod_type: Project::A_TYPE_NUGET,
      language: Product::A_LANGUAGE_CSHARP,
      version: "2.1"
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

    it "matches less than rule" do
      less_than = parser.rules[:less_than]
      less_than.match("(,1)").should_not be_nil
      less_than.match("(,1.0)").should_not be_nil
      less_than.match("(,1.2.2)").should_not be_nil
    end

    it "matches less equal rules" do
      less_equal = parser.rules[:less_equal]
      less_equal.match("(,1]").should_not be_nil
      less_equal.match("(,1.0]").should_not be_nil
      less_equal.match("(,2.2.0]").should_not be_nil
    end
   
    it "matches rule of exact match" do
      exact = parser.rules[:exact]
      exact.match("[1]").should_not be_nil
      exact.match("[1.0]").should_not be_nil
      exact.match("[2.0.1]").should_not be_nil
      exact.match("[2.0.1,]").should_not be_nil
    end

    it "matches rule of greater_than" do
      greater_than = parser.rules[:greater_than]
      greater_than.match("(1,)").should_not be_nil
      greater_than.match("(1.0,)").should_not be_nil
      greater_than.match("(1.2.0,)").should_not be_nil
    end

    it "matches rule of greater_eq_than" do
      greater_than = parser.rules[:greater_eq_than]
      greater_than.match("1").should_not be_nil
      greater_than.match("1.0").should_not be_nil
      greater_than.match("1.2.0").should_not be_nil
    end

    it "matches range 1.0 < x < 2.0" do
      range = parser.rules[:gt_range_lt]
      range.match("(1,2)").should_not be_nil
      range.match("(1.0,2.0)").should_not be_nil
      range.match("(1.0,2.0.1)").should_not be_nil
    end

    it "matches range 1.0 <= x < 2.0" do
      range = parser.rules[:gte_range_lt]
      range.match("[1,2)").should_not be_nil
      range.match("[1.0,2.0)").should_not be_nil
      range.match("[1.0,2.0.2)").should_not be_nil
    end

    it "matches range 1.0 < x <= 2.0" do 
      range = parser.rules[:gt_range_lte]
      range.match("(1,2]").should_not be_nil
      range.match("(1.0,2.0]").should_not be_nil
      range.match("(1.0,2.0.3]").should_not be_nil
    end

    it "matches range 1.0 <= x <= 2.0" do
      range = parser.rules[:gte_range_lte]
      range.match("[1,2]").should_not be_nil
      range.match("[1.0,2.0]").should_not be_nil
      range.match("[1.2.1,2.0]").should_not be_nil
      range.match("[1.2.1,2.0+build.1]").should_not be_nil
   end
  end

  context "parse_version_data" do
    before :each do
      product3.versions << FactoryGirl.build(:product_version, version: "1.0")
      product3.versions << FactoryGirl.build(:product_version, version: "1.2")
      product3.versions << FactoryGirl.build(:product_version, version: "1.3")
      product3.versions << FactoryGirl.build(:product_version, version: "1.6")
      product3.versions << FactoryGirl.build(:product_version, version: "1.9")
      product3.versions << FactoryGirl.build(:product_version, version: "2.0")
      product3.versions << FactoryGirl.build(:product_version, version: "2.1")
      product3.save
    end

    it "returns unparsed label when product is nil" do
      version_data = parser.parse_version_data("0.9", nil)
      version_data.should_not be_nil
      version_data[:version].should eq("0.9")
      version_data[:label].should eq("0.9")
      version_data[:comperator].should eq("=")
    end

    it "returns latest version when version_label is empty string" do
      version_data = parser.parse_version_data(nil, product3)
      version_data.should_not be_nil
      version_data[:label].should eq("")
      version_data[:version].should eq("2.1")
      version_data[:comperator].should eq(">=")
    end

    it "returns exact version when version label is [1.6]" do
      version_data = parser.parse_version_data("[1.6]", product3)
      version_data.should_not be_nil
      version_data[:label].should eq("[1.6]")
      version_data[:version].should eq("1.6")
      version_data[:comperator].should eq("=")
    end

    it "returns latest version for requested version (,1.6)" do
      version_data = parser.parse_version_data("(,1.6)", product3)
      version_data.should_not be_nil
      version_data[:label].should eq("(,1.6)")
      version_data[:version].should eq("1.3")
      version_data[:comperator].should eq("<")
    end

    it "returns correct version for requested version (,1.6]" do
      version_data = parser.parse_version_data("(,1.6]", product3)
      version_data.should_not be_nil
      version_data[:label].should eq("(,1.6]")
      version_data[:version].should eq("1.6")
      version_data[:comperator].should eq("<=")
    end

    it "returns correct version for requested version (1.6,)" do
      version_data = parser.parse_version_data("(1.6,)", product3)
      version_data.should_not be_nil
      version_data[:label].should eq("(1.6,)")
      version_data[:version].should eq("2.1")
      version_data[:comperator].should eq(">")
    end

    it "returns correct version for requested version 1.6" do
      version_data = parser.parse_version_data("1.6", product3)
      version_data.should_not be_nil
      version_data[:label].should eq("1.6")
      version_data[:version].should eq("2.1")
      version_data[:comperator].should eq(">=")
    end

    it "returns correct version for requested version (1.6, 2.0)" do
      version_data = parser.parse_version_data("(1.6, 2.0)", product3)
      version_data.should_not be_nil
      version_data[:label].should eq("(1.6,2.0)")
      version_data[:version].should eq("1.9")
      version_data[:comperator].should eq(">x<")
    end

    it "returns correct version for requested version [1.6, 2.0)" do
      version_data = parser.parse_version_data("[1.6, 2.0)", product3)
      version_data.should_not be_nil
      version_data[:label].should eq("[1.6,2.0)")
      version_data[:version].should eq("1.9")
      version_data[:comperator].should eq(">=x<")
    end

    it "returns correct version for requested version (1.6, 2.0]" do
      product1.save
      version_data = parser.parse_version_data("(1.6, 2.0]", product3)
      version_data.should_not be_nil
      version_data[:label].should eq("(1.6,2.0]")
      version_data[:version].should eq("2.0")
      version_data[:comperator].should eq(">x<=")
    end

    it "returns correct version for requested version [1.6, 2.0]" do
      version_data = parser.parse_version_data("[1.6, 2.0]", product3)
      version_data.should_not be_nil
      version_data[:label].should eq("[1.6,2.0]")
      version_data[:version].should eq("2.0")
      version_data[:comperator].should eq(">=x<=")
    end
  end


  context "parse" do
    it "fetches file properly" do
      project = parser.parse(test_file_url)
      project.should_not be_nil
    end

    it "parses the file correctly" do
      project = parser.parse(test_file_url)
      project.should_not be_nil

      project.projectdependencies.size.should eq(4)

      dep1 = project.dependencies[0]
      dep1.name.should eq(product1[:name])
      dep1.version_requested.should eq(product1[:version])
      dep1.target.should eq("net40")
      dep1.comperator.should eq("=")

      dep2 = project.dependencies[1]
      dep2.name.should eq(product1[:name])
      dep2.version_requested.should eq(product1[:version])
      dep2.target.should eq("net45")
      dep2.comperator.should eq("=")

      dep3 = project.dependencies[2]
      dep3.name.should eq(product1[:name])
      dep3.version_requested.should eq(product1[:version])
      dep3.target.should eq("portable-net45+sl5+netcore45+wp8")

      dep4 = project.dependencies[3]
      dep4.name.should eq(product2[:name])
      dep4.version_requested.should eq(product2[:version])
      dep4.target.should eq("portable-net45+sl5+netcore45+wp8")
    end

  end
end
