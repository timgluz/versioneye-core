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
      expect( "1".match(version) ).not_to  be_nil
      expect( "1.0".match(version) ).not_to  be_nil
      expect( "1.1.0".match(version) ).not_to be_nil
      expect( "  1.1.0".match(version) ).not_to be_nil
      expect( "1.1.0  ".match(version) ).not_to be_nil
      expect( "  1.1.0  ".match(version) ).not_to be_nil
    end

    it "matches semantic versions" do
      semver = parser.rules[:semver]
      expect( "1.0-alpha".match(semver)     ).not_to be_nil
      expect( "1.0-alpha.1".match(semver)   ).not_to be_nil
      expect( "1.0-alpha-1.0".match(semver) ).not_to be_nil
      expect( "1.0+build".match(semver) ).not_to be_nil
      expect( "1.0+build.1".match(semver) ).not_to be_nil
      expect( "1.0-alpha+build".match(semver) ).not_to be_nil
      expect( "1.0-alpha.1.2+build.2".match(semver) ).not_to be_nil
    end

    it "matches patched_patch semvers" do
      semver = parser.rules[:semver]

      expect( semver.match '2.0.30506.0' ).not_to be_nil
      expect( semver.match '1.6.6.0' ).not_to be_nil
      expect( semver.match '0.18.3.1' ).not_to be_nil
      expect( semver.match '0.18.3.1.2.3' ).not_to be_nil

    end

    it "matches less than rule" do
      less_than = parser.rules[:less_than]

      expect( less_than.match("(,1)") ).not_to be_nil
      expect( less_than.match("(,1.0)") ).not_to be_nil
      expect( less_than.match("(,1.2.2)") ).not_to be_nil
    end

    it "matches less equal rules" do
      less_equal = parser.rules[:less_equal]

      expect( less_equal.match("(,1]") ).not_to be_nil
      expect( less_equal.match("(,1.0]") ).not_to be_nil
      expect( less_equal.match("(,2.2.0]") ).not_to be_nil
    end

    it "matches rule of exact match" do
      exact = parser.rules[:exact]

      expect( exact.match("[1]") ).not_to be_nil
      expect( exact.match("[1.0]") ).not_to be_nil
      expect( exact.match("[2.0.1]") ).not_to be_nil
      expect( exact.match("[2.0.1,]") ).not_to be_nil
    end

    it "matches rule of greater_than" do
      greater_than = parser.rules[:greater_than]

      expect( greater_than.match("(1,)") ).not_to be_nil
      expect( greater_than.match("(1.0,)") ).not_to be_nil
      expect( greater_than.match("(1.2.0,)") ).not_to be_nil
    end

    it "matches rule of greater_eq_than" do
      greater_than = parser.rules[:greater_eq_than]

      expect( greater_than.match("1") ).not_to be_nil
      expect( greater_than.match("1.0") ).not_to be_nil
      expect( greater_than.match("1.2.0") ).not_to be_nil
    end

    it "matches rule of greater_eq_than2" do
      greater_than = parser.rules[:greater_eq_than2]

      expect( greater_than.match("[1,)") ).not_to be_nil
      expect( greater_than.match("[1.0,)") ).not_to be_nil
      expect( greater_than.match("[1.2.0,)") ).not_to be_nil

    end

    it "matches range 1.0 < x < 2.0" do
      range = parser.rules[:gt_range_lt]

      expect( range.match("(1,2)") ).not_to be_nil
      expect( range.match("(1.0,2.0)") ).not_to be_nil
      expect( range.match("(1.0,2.0.1)") ).not_to be_nil
    end

    it "matches range 1.0 <= x < 2.0" do
      range = parser.rules[:gte_range_lt]

      expect( range.match("[1,2)") ).not_to be_nil
      expect( range.match("[1.0,2.0)") ).not_to be_nil
      expect( range.match("[1.0,2.0.2)") ).not_to be_nil
    end

    it "matches range 1.0 < x <= 2.0" do
      range = parser.rules[:gt_range_lte]

      expect( range.match("(1,2]") ).not_to be_nil
      expect( range.match("(1.0,2.0]") ).not_to be_nil
      expect( range.match("(1.0,2.0.3]") ).not_to be_nil
    end

    it "matches range 1.0 <= x <= 2.0" do
      range = parser.rules[:gte_range_lte]

      expect( range.match("[1,2]") ).not_to be_nil
      expect( range.match("[1.0,2.0]") ).not_to be_nil
      expect( range.match("[1.2.1,2.0]") ).not_to be_nil
      expect( range.match("[1.2.1,2.0+build.1]") ).not_to be_nil
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

      expect( version_data ).not_to be_nil
      expect( version_data[:version]  ).to eq("0.9")
      expect( version_data[:label]    ).to eq("0.9")
      expect( version_data[:comperator] ).to eq("=")
    end

    it "returns latest version when version_label is empty string" do
      version_data = parser.parse_version_data(nil, product3)

      expect( version_data ).not_to be_nil
      expect( version_data[:label] ).to eq("*")
      expect( version_data[:version] ).to eq("2.1")
      expect( version_data[:comperator] ).to eq('=')
    end

    it "returns exact version when version label is [1.6]" do
      version_data = parser.parse_version_data("[1.6]", product3)

      expect( version_data ).not_to be_nil
      expect( version_data[:label] ).to eq("[1.6]")
      expect( version_data[:version] ).to eq("1.6")
      expect( version_data[:comperator] ).to eq("=")
    end

    it "returns latest version for requested version (,1.6)" do
      version_data = parser.parse_version_data("(,1.6)", product3)

      expect( version_data ).not_to be_nil
      expect( version_data[:label] ).to eq("(,1.6)")
      expect( version_data[:version] ).to eq("1.3")
      expect( version_data[:comperator] ).to eq("<")
    end

    it "returns correct version for requested version (,1.6]" do
      version_data = parser.parse_version_data("(,1.6]", product3)

      expect( version_data ).not_to be_nil
      expect( version_data[:label] ).to eq("(,1.6]")
      expect( version_data[:version] ).to eq("1.6")
      expect( version_data[:comperator] ).to eq("<=")
    end

    it "returns correct version for requested version (1.6,)" do
      version_data = parser.parse_version_data("(1.6,)", product3)

      expect( version_data ).not_to be_nil
      expect( version_data[:label] ).to eq("(1.6,)")
      expect( version_data[:version] ).to eq("2.1")
      expect( version_data[:comperator] ).to eq(">")
    end

    it "returns correct version for requested version 1.6" do
      version_data = parser.parse_version_data("1.6", product3)

      expect( version_data).not_to be_nil
      expect( version_data[:label] ).to eq("1.6")
      expect( version_data[:version] ).to eq("2.1")
      expect( version_data[:comperator] ).to eq(">=")
    end

    it "returns correct version for requested version (1.6, 2.0)" do
      version_data = parser.parse_version_data("(1.6, 2.0)", product3)

      expect( version_data).not_to be_nil
      expect( version_data[:label] ).to eq("(1.6,2.0)")
      expect( version_data[:version] ).to eq("1.9")
      expect( version_data[:comperator] ).to eq(">x<")
    end

    it "returns correct version for requested version [1.6, 2.0)" do
      version_data = parser.parse_version_data("[1.6, 2.0)", product3)

      expect( version_data ).not_to be_nil
      expect( version_data[:label]).to eq("[1.6,2.0)")
      expect( version_data[:version]).to eq("1.9")
      expect( version_data[:comperator]).to eq(">=x<")
    end

    it "returns correct version for requested version (1.6, 2.0]" do
      product1.save
      version_data = parser.parse_version_data("(1.6, 2.0]", product3)

      expect( version_data).not_to be_nil
      expect( version_data[:label]).to eq("(1.6,2.0]")
      expect( version_data[:version]).to eq("2.0")
      expect( version_data[:comperator]).to eq(">x<=")
    end

    it "returns correct version for requested version [1.6, 2.0]" do
      version_data = parser.parse_version_data("[1.6, 2.0]", product3)

      expect( version_data).not_to be_nil
      expect( version_data[:label]).to eq("[1.6,2.0]")
      expect( version_data[:version]).to eq("2.0")
      expect( version_data[:comperator]).to eq(">=x<=")
    end
  end


  context "parse" do
    it "fetches file properly" do
      project = parser.parse(test_file_url)
      expect( project ).not_to be_nil
    end

    it "parses the file correctly" do
      project = parser.parse(test_file_url)
      expect(project).to_not be_nil

      expect( project.projectdependencies.size ).to eq(4)

      dep1 = project.dependencies[0]
      expect( dep1.name).to eq(product1[:name])
      expect( dep1.version_requested).to eq(product1[:version])
      expect( dep1.target).to eq("net40")
      expect( dep1.comperator).to eq("=")

      dep2 = project.dependencies[1]
      expect( dep2.name).to eq(product1[:name])
      expect( dep2.version_requested).to eq(product1[:version])
      expect( dep2.target).to eq("net45")
      expect( dep2.comperator).to eq("=")

      dep3 = project.dependencies[2]
      expect( dep3.name).to eq(product1[:name])
      expect( dep3.version_requested).to eq(product1[:version])
      expect( dep3.target).to eq("portable-net45+sl5+netcore45+wp8")

      dep4 = project.dependencies[3]
      expect( dep4.name).to eq(product2[:name])
      expect( dep4.version_requested).to eq(product2[:version])
      expect( dep4.target).to eq("portable-net45+sl5+netcore45+wp8")
    end
  end

  let(:product4){
    FactoryGirl.create(
      :product,
      prod_type: Project::A_TYPE_NUGET,
      language: Product::A_LANGUAGE_CSHARP,
      version: "2.0",
    )
  }

  let(:depx){
    FactoryGirl.create(
      :projectdependency,
      language: Product::A_LANGUAGE_CSHARP,
      version_requested: '',
      comperator: '?'
    )
  }


  context "parse_requested_version" do
    before :each do
      product4.versions << FactoryGirl.build(:product_version, version: '0.9')
      product4.versions << FactoryGirl.build(:product_version, version: '1.0')
      product4.versions << FactoryGirl.build(:product_version, version: '1.3')
      product4.versions << FactoryGirl.build(:product_version, version: '1.5')
      product4.versions << FactoryGirl.build(:product_version, version: '2.0')

      product4.save
    end


    it "uses the latest product version when version_label is nil" do
      res = parser.parse_requested_version(nil, depx, product4)

      expect(res).not_to be_nil
      expect(res[:version_requested]).to eq(product4[:version])
      expect(res[:version_label]).to eq('*')
      expect(res[:comperator]).to eq('=')
    end

    it "returns the latest version which is smaller than 1.5" do
      res = parser.parse_requested_version('(,1.5)', depx, product4)

      expect(res).not_to be_nil
      expect(res[:version_requested]).to eq('1.3')
      expect(res[:version_label]).to eq('(,1.5)')
      expect(res[:comperator]).to eq('<')
    end

    it "returns the latest version which is smaller or equal than 1.5" do
      res = parser.parse_requested_version('(,1.5]', depx, product4)

      expect(res).not_to be_nil
      expect(res[:version_requested]).to eq('1.5')
      expect(res[:version_label]).to eq('(,1.5]')
      expect(res[:comperator]).to eq('<=')
    end

    it "returns the exact match" do
      res = parser.parse_requested_version('[1.5]', depx, product4)

      expect(res).not_to be_nil
      expect(res[:version_requested]).to eq('1.5')
      expect(res[:version_label]).to eq('[1.5]')
      expect(res[:comperator]).to eq('=')
    end

    it "returns the latest version which is bigger than 1.3" do
      res = parser.parse_requested_version('(1.3,)', depx, product4)

      expect(res).not_to be_nil
      expect(res[:version_requested]).to eq('2.0')
      expect(res[:version_label]).to eq('(1.3,)')
      expect(res[:comperator]).to eq('>')
    end

    it "returns the latest version which is bigger or equal than 2.0" do
      res = parser.parse_requested_version('1.5', depx, product4)

      expect(res).not_to be_nil
      expect(res[:version_requested]).to eq('2.0')
      expect(res[:version_label]).to eq('1.5')
      expect(res[:comperator]).to eq('>=')
    end

    it "returns latest version in between range 1.0 < x < 1.5" do
      res = parser.parse_requested_version('(1.0,1.5)', depx, product4)

      expect(res).not_to be_nil
      expect(res[:version_requested]).to eq('1.3')
      expect(res[:version_label]).to eq('(1.0,1.5)')
      expect(res[:comperator]).to eq('>x<')
    end

    it "returns the latest version between range 1.5 <= x < 2.0" do
      res = parser.parse_requested_version('[1.5,2.0)', depx, product4)

      expect(res).not_to be_nil
      expect(res[:version_requested]).to eq('1.5')
      expect(res[:version_label]).to eq('[1.5,2.0)')
      expect(res[:comperator]).to eq('>=x<')
    end

    it "returns the latest version between range 1.0 < x <= 1.5" do
      res = parser.parse_requested_version('(1.0,1.5]', depx, product4)

      expect(res).not_to be_nil
      expect(res[:version_requested]).to eq('1.5')
      expect(res[:version_label]).to eq('(1.0,1.5]')
      expect(res[:comperator]).to eq('>x<=')
    end

    it "returns the latest version between range 1.0 <= x <= 2.0" do
      res = parser.parse_requested_version('[1.0,2.0]', depx, product4)

      expect(res).not_to be_nil
      expect(res[:version_requested]).to eq('2.0')
      expect(res[:version_label]).to eq('[1.0,2.0]')
      expect(res[:comperator]).to eq('>=x<=')
    end

    it "returns the version label from the file, when product has no matching versions" do
      res = parser.parse_requested_version('24.12.0', depx, product4)

      expect(res).not_to be_nil
      expect(res[:version_requested]).to eq('24.12.0')
      expect(res[:version_label]).to eq('24.12.0')
      expect(res[:comperator]).to eq('>=')
    end

    it "doesnt mark outdated if latest product is not stable and version_label is fixed on latest stable" do
      product4.version = '2.0' # it's latest stable version
      product4.versions << FactoryGirl.build( :product_version, version: '2.1-alpha')

      #none of those example should return alpha version
      res = parser.parse_requested_version('2.0', depx, product4)
      expect(res).not_to be_nil
      expect(res[:version_requested]).to eq('2.0')
      expect(res[:version_label]).to eq('2.0')
      expect(res[:comperator]).to eq('>=')

      res = parser.parse_requested_version('(1.9,)', depx, product4)
      expect(res).not_to be_nil
      expect(res[:version_requested]).to eq('2.0')
      expect(res[:version_label]).to eq('(1.9,)')
      expect(res[:comperator]).to eq('>')


      res = parser.parse_requested_version('(,2.2)', depx, product4)
      expect(res).not_to be_nil
      expect(res[:version_requested]).to eq('2.0')
      expect(res[:comperator]).to eq('<')

      res = parser.parse_requested_version('(,2.2]', depx, product4)
      expect(res).not_to be_nil
      expect(res[:version_requested]).to eq('2.0')
      expect(res[:comperator]).to eq('<=')
    end
  end
end
