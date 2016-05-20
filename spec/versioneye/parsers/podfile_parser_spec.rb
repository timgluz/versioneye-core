require 'spec_helper'

describe PodfileParser do

  let( :parser ) { PodfileParser.new }

  describe '.parse' do

    it 'parses remote urls' do
      project = PodfileParser.new.parse 'https://raw.githubusercontent.com/CocoaPods/Core/master/spec/fixtures/Podfile'
      expect( project ).to_not be_nil
      expect( project.language ).to eq Product::A_LANGUAGE_OBJECTIVEC
      expect( project.project_type ).to eq Project::A_TYPE_COCOAPODS
    end

    it "should drop subspecs and just use the main spec" do

      # TODO add this before so the subspecs are actually known
      # 'https://raw.github.com/CocoaPods/Specs/master/ShareKit/2.4.6/ShareKit.podspec'
      # 'https://raw.github.com/CocoaPods/Specs/master/xmlrpc/2.3.3/xmlrpc.podspec'

      podfile = 'https://raw.githubusercontent.com/DenisDbv/OpenAuth/8d654f25d540ec865a8faeace40a810b7bdc9ff2/Podfile'
      project = PodfileParser.new.parse( podfile )
      expect( project ).to_not be_nil

      deps = project.dependencies

      expect( deps.size ).to eq(2)
      deps.each do |dep|
        expect( %w{ShareKit xmlrpc} ).to be_member(dep.name)
      end
    end

  end

  describe '.parse_file' do

    def create_pods
      ssl_tool_kit = ProductFactory.create_for_cocoapods("SSToolkit", "2.3.4")
      ssl_tool_kit.save

      afnetworking = ProductFactory.create_for_cocoapods("AFNetworking", "0.2.1")
      afnetworking.versions.push(Version.new({:version => "0.2.0"}))
      afnetworking.save

      lumberjack   = ProductFactory.create_for_cocoapods("CocoaLumberjack", "1.2.3")
      lumberjack.versions.push(Version.new({:version => "1.2.0"}))
      lumberjack.save

      jsonkit   = ProductFactory.create_for_cocoapods("JSONKit", "1.1.0")
      jsonkit.versions.push(Version.new({:version => "1.2.0"}))
      jsonkit.save

      objection   = ProductFactory.create_for_cocoapods("Objection", "1.0.0")
      objection.save
    end

    def get_dependency project, name
      project.dependencies.each do |dep|
        return dep if dep.name.eql?( name )
      end
      return nil
    end

    def parse_and_check podfile_path
      project = parser.parse_file podfile_path
      expect( project ).to be_truthy
      expect( project.language ).to eq Product::A_LANGUAGE_OBJECTIVEC
      expect( project.project_type ).to eq Project::A_TYPE_COCOAPODS
      project
    end

    def test_dependency dep, version_current, version_requested, outdated
      expect( dep.version_current ).to eq(version_current)
      expect( dep.version_requested ).to eq(version_requested)
      expect( dep.outdated ).to eq(outdated)
    end

    def cocoa_product(product_name, latest_version, *other_versions)
      new_product = ProductFactory.create_for_cocoapods(product_name, latest_version)
      other_versions.each do |a_version|
        new_product.versions.push(Version.new({:version => a_version}))
      end
      new_product.save
      new_product
    end


    it "should read a simple podfile and return project, dependencies" do
      create_pods
      project = parse_and_check './spec/fixtures/files/pod_file/example1/Podfile'
      expect( project.dependencies.count ).to eq 6

      dep_ssl_tool_kit = get_dependency(project, "SSToolkit")
      expect( dep_ssl_tool_kit.version_current ).to eq "2.3.4"
      expect( dep_ssl_tool_kit.version_requested ).to eq "2.3.4"
      expect( dep_ssl_tool_kit.outdated ).to be_falsey

      dep_afnetworking = get_dependency(project, "AFNetworking")
      expect( dep_afnetworking.version_current ).to eq "0.2.1"
      expect( dep_afnetworking.version_requested ).to eq "0.2.1"
      expect( dep_afnetworking.outdated ).to be_falsey

      dep_lumberjack = get_dependency(project, "CocoaLumberjack")
      expect( dep_lumberjack.version_current ).to eq "1.2.3"
      expect( dep_lumberjack.version_requested ).to eq "1.2.3"
      expect( dep_lumberjack.outdated ).to be_falsey

      dep_jsonkit = get_dependency(project, "JSONKit")
      expect( dep_jsonkit.version_current ).to eq "1.2.0"
      expect( dep_jsonkit.version_requested ).to eq "1.1.0"
      expect( dep_jsonkit.outdated ).to be_truthy

      dep_jsonkit = get_dependency(project, "Objection")
      expect( dep_jsonkit.version_current ).to eq "1.0.0"
      expect( dep_jsonkit.version_requested ).to eq "1.0.0"
      expect( dep_jsonkit.version_label ).to eq ">= 0"
      expect( dep_jsonkit.comperator ).to eq ">="
      expect( dep_jsonkit.outdated ).to be_falsey
    end

    it "should parse a podfile with target definitions" do

      # setup
      cocoa_product( 'TestFlightSDK',   '2.0.2', '2.1.1-beta',     '2.0',  '1.3')
      cocoa_product( 'MBProgressHUD',   '0.8',   '0.7',   '0.6',   '0.5')
      cocoa_product( 'iRate',           '1.8.2', '1.8',   '1.7.5', '1.6.2')
      cocoa_product( 'TimesSquare',     '1.0.1', '1.0.0')
      cocoa_product( 'AFNetworking',    '2.0.2', '2.0.0', '1.3.3')
      cocoa_product( 'KKPasscodeLock',  '0.2.2', '0.1.5')
      cocoa_product( 'iCarousel',       '1.7.6', '1.7.4', '1.7',   '1.6.3')

      # run
      project = parse_and_check "./spec/fixtures/files/pod_file/target_example1/Podfile"

      # test
      expect( project.dependencies.count ).to eq 7

      dep = get_dependency(project,  'TestFlightSDK')
      test_dependency(dep, '2.0.2', '2.0.2', false)

      dep = get_dependency(project,  'MBProgressHUD')
      test_dependency(dep, '0.8',   '0.5',   true)

      dep = get_dependency(project,  'iRate')
      test_dependency(dep, '1.8.2', '1.8.2', false)

      dep = get_dependency(project,  'TimesSquare')
      test_dependency(dep, '1.0.1', '1.0.1', false)

      dep = get_dependency(project,  'AFNetworking')
      test_dependency(dep, '2.0.2', '1.1.0', true)

      dep = get_dependency(project,  'KKPasscodeLock')
      test_dependency(dep, '0.2.2', '0.1.5', true)

      dep = get_dependency(project,  'iCarousel')
      test_dependency(dep, '1.7.6', '1.7.4', true)
    end

    it "should parse a podfile with target definitions" do

      # setup
      cocoa_product("SSKeychain",            "1.2.1", "0.2.1", "0.1.4")
      cocoa_product("INAppStoreWindow",      "1.3",   "1.2",   "1.1", "1.0")
      cocoa_product("AFNetworking",          "2.0.2", "2.0.0", "1.3.3")
      cocoa_product("Reachability",          "3.1.1", "3.1.0", "3.0.0")
      cocoa_product("KSADNTwitterFormatter", "0.2.0", "0.1.0") # can't find this on VersionEye
      cocoa_product("MASShortcut",           "1.2.2", "1.2",   "1.1")
      cocoa_product("MagicalRecord",         "2.2",   "2.0",   "1.1.8")
      cocoa_product("MASPreferences",        "1.0")

      project = parse_and_check "./spec/fixtures/files/pod_file/target_example2/Podfile"
      expect( project.dependencies.count ).to eq 8

      dep = get_dependency(project, "SSKeychain")
      test_dependency(dep, "1.2.1", "0.1.4", true)

      # currently this dependency is not outdated, but will be soon
      dep = get_dependency(project, "INAppStoreWindow")
      test_dependency(dep, "1.3",   "1.3",   false)

      dep = get_dependency(project, "AFNetworking")
      test_dependency(dep, "2.0.2", "1.1.0", true)

      dep = get_dependency(project, "Reachability")
      test_dependency(dep, "3.1.1", "3.1.1", false)

      dep = get_dependency(project, "KSADNTwitterFormatter")
      test_dependency(dep, "0.2.0", "0.1.0", true)

      dep = get_dependency(project, "MASShortcut")
      test_dependency(dep, "1.2.2", "1.2.2", false)

      dep = get_dependency(project, "MagicalRecord")
      test_dependency(dep, "2.2",   "2.1",   true)

      dep = get_dependency(project, "MASPreferences")
      test_dependency(dep, "1.0",   "1.0",   false)
    end


    it "should parse simple targets in podfile" do

      # setup
      cocoa_product('Kiwi',            '2.2.3', '2.2', '2.1')
      cocoa_product('CocoaLumberjack', '1.6.3', '1.6', '1.3')

      # run
      project = parse_and_check './spec/fixtures/files/pod_file/target_example_3/Podfile'

      # check
      expect( project.dependencies.count ).to eq 3 # TODO check why this isn't 2

      dep = get_dependency(project, 'Kiwi')
      test_dependency(dep, '2.2.3', '2.2.3', false)

      dep = get_dependency(project, 'CocoaLumberjack')
      test_dependency(dep, '1.6.3', '1.6.3', false)

    end

  end

end
