require 'spec_helper'

describe GemfileParser do

  describe "helper functions" do
    let(:parser){ GemfileParser.new }

    describe "strip_platform_quotes" do
      it "returns non-matching strings untouched" do
        expect( parser.strip_platform_exts('1.0.0')   ).to eq('1.0.0')
        expect( parser.strip_platform_exts('1.0-abc') ).to eq('1.0-abc')
        expect( parser.strip_platform_exts('1.0-a-b') ).to eq('1.0-a-b')
      end

      it "filters out known platform extensions" do
        expect( parser.strip_platform_exts('1.0-x64')       ).to eq('1.0')
        expect( parser.strip_platform_exts('1.0-a-x86')     ).to eq('1.0-a')
        expect( parser.strip_platform_exts('1.0-java')      ).to eq('1.0')
        expect( parser.strip_platform_exts('1.0-java-b-c')  ).to eq('1.0-b-c')
        expect( parser.strip_platform_exts('1.0-mingw32')   ).to eq('1.0')
      end
    end

    describe "parse_gem_file" do
      it "parses correctly default gem line" do
        gem_doc = parser.parse_gem_line('gem "abc", "2.3.4"')

        expect(gem_doc).not_to be_nil
        expect(gem_doc[:name]).to eq("abc")
        expect(gem_doc[:version]).to eq("2.3.4")
      end

      it "parses correcty long gem line" do
        gem_line = 'gem "abc2", ">= 2.3.4", :require => true, :group => test'
        gem_doc = parser.parse_gem_line(gem_line)

        expect(gem_doc).not_to be_nil
        expect(gem_doc[:name]).to eq('abc2')
        expect(gem_doc[:version]).to eq('>= 2.3.4')
        expect(gem_doc[:require]).to eq('true')
        expect(gem_doc[:group]).to eq('test')
      end

      it "parses correctly a line with multiple version range" do
        gem_line = 'gem "abc3", "> 1.0.1", "<= 1.8.1", "!= 1.3.4, :group => "test"'
        gem_doc = parser.parse_gem_line(gem_line)

        expect(gem_doc).not_to be_nil
        expect(gem_doc[:name]).to eq('abc3')
        expect(gem_doc[:versions].size).to eq(3)
        expect(gem_doc[:version]).to eq('> 1.0.1,<= 1.8.1,!= 1.3.4')
        expect(gem_doc[:group]).to eq('test')
      end

      it "parses correctly gem line with github coords" do
        gem_line = 'gem "abc4", :github => "rails/rails", :branch => "master", :tag=>"v1.2.3"'
        gem_doc = parser.parse_gem_line(gem_line)

        expect(gem_doc).not_to be_nil
        expect(gem_doc[:name]).to eq('abc4')
        expect(gem_doc[:versions].empty? ).to be_truthy
        expect(gem_doc[:version].empty?).to be_truthy
        expect(gem_doc[:github]).to eq('rails/rails')
        expect(gem_doc[:branch]).to eq('master')
        expect(gem_doc[:tag]).to eq('v1.2.3')
      end

      it "parses correctly keys as Ruby symbols" do
        gem_line = 'gem "abc5", github: "rails/rails", branch: "master", tag: "v1.2.3"'
        gem_doc = parser.parse_gem_line(gem_line)

        expect(gem_doc).not_to be_nil
        expect(gem_doc[:name]).to eq('abc5')
        expect(gem_doc[:versions].empty? ).to be_truthy
        expect(gem_doc[:version].empty?).to be_truthy
        expect(gem_doc[:github]).to eq('rails/rails')
        expect(gem_doc[:branch]).to eq('master')
        expect(gem_doc[:tag]).to eq('v1.2.3')
      end

      it "parses correctly list items" do
        gem_line = 'gem "tzinfo-data", "= 3.0.3", platforms: [:mingw, :mswin]'
        gem_doc = parser.parse_gem_line(gem_line)

        expect(gem_doc).not_to be_nil
        expect(gem_doc[:name]).to eq('tzinfo-data')
        expect(gem_doc[:version]).to eq('= 3.0.3')
        expect(gem_doc[:platforms]).to eq('[:mingw, :mswin]')
      end
    end

  end

  describe "parse" do

    def fetch_by_name(dependencies, name)
      dependencies.each do |dep|
        return dep if dep.name.eql? name
      end
    end

    it "parse from https the file correctly" do
      parser = GemfileParser.new
      project = parser.parse("https://s3.amazonaws.com/veye_test_env/Gemfile")
      expect( project ).not_to be_nil
    end

    it "parse from http the file correctly" do
      product1 = ProductFactory.create_for_gemfile("execjs", "1.4.0")
      product1.versions.push( Version.new({version: "1.3.0"}) )
      product1.save

      product2 = ProductFactory.create_for_gemfile("jquery-rails", "1.0.0")
      product2.save

      product3 = ProductFactory.create_for_gemfile("therubyracer", "0.11.3")
      product3.versions.push( Version.new({version: "0.10.1"}) )
      product3.save

      product4 = ProductFactory.create_for_gemfile("will_paginate", "4.0.3")
      product4.versions.push( Version.new({version: "3.0.3"}) )
      product4.save

      product5 = ProductFactory.create_for_gemfile("gravatar_image_tag", "1.1.6")
      product5.versions.push( Version.new({version: "1.1.3"}) )
      product5.save

      product6 = ProductFactory.create_for_gemfile("tire", "3.2.5")
      product6.save

      product7 = ProductFactory.create_for_gemfile("sass-rails", "3.3.9")
      product7.versions.push( Version.new({version: "3.2.5"}) )
      product7.versions.push( Version.new({version: "3.2.9"}) )
      product7.save

      product8 = ProductFactory.create_for_gemfile("sassy", "3.3.9")
      product8.versions.push( Version.new({version: "3.2.5"}) )
      product8.versions.push( Version.new({version: "3.2.9"}) )
      product8.save

      product9 = ProductFactory.create_for_gemfile("cucumber-rails", "1.0.0")
      product9.save

      product10 = ProductFactory.create_for_gemfile("fastercsv", "1.0.0")
      product10.save

      product11 = ProductFactory.create_for_gemfile("guard-livereload", "1.0.0")
      product11.save

      product12 = ProductFactory.create_for_gemfile("copycopter_client", "1.0.0")
      product12.save

      product13 = ProductFactory.create_for_gemfile("govkit", "1.0.0")
      product13.save

      product14 = ProductFactory.create_for_gemfile("libnotify", "1.0.0")
      product14.save

      product15 = ProductFactory.create_for_gemfile("growl", "3.3.3")
      product15.save


      parser  = GemfileParser.new
      project = parser.parse("http://s3.amazonaws.com/veye_test_env/Gemfile")
      expect( project ).not_to be_nil
      expect( project.dependencies.size ).to eql(15)

      dep_1 = fetch_by_name project.dependencies, "rails"
      expect( dep_1.name ).to eql("rails")
      expect( dep_1.version_requested).to eql("3.2.6")
      expect( dep_1.comperator).to eql("=")
      expect( dep_1.language ).to eql(Product::A_LANGUAGE_RUBY)

      dep_2 = fetch_by_name project.dependencies, "jquery-rails"
      expect( dep_2.name).to eql("jquery-rails")
      expect( dep_2.version_requested).to eql("1.0.0")
      expect( dep_2.version_current).to eql("1.0.0")
      expect( dep_2.comperator).to eql("=")
      expect( dep_2.language ).to eql(Product::A_LANGUAGE_RUBY)

      dep_3 = fetch_by_name project.dependencies, "execjs"
      expect( dep_3.name).to eql("execjs")
      expect( dep_3.version_requested).to eql("1.3.0")
      expect( dep_3.version_current).to eql("1.4.0")
      expect( dep_3.version_label).to eql("1.4.0")
      expect( dep_3.comperator).to eql("<")
      expect( dep_3.language ).to eql(Product::A_LANGUAGE_RUBY)

      dep_4 = fetch_by_name project.dependencies, "therubyracer"
      expect( dep_4.name).to eql("therubyracer")
      expect( dep_4.version_requested).to eql("0.11.3")
      expect( dep_4.version_current).to eql("0.11.3")
      expect( dep_4.version_label).to eql("0.10.1")
      expect( dep_4.comperator).to eql(">")
      expect( dep_4.language ).to eql(Product::A_LANGUAGE_RUBY)

      dep_5 = fetch_by_name project.dependencies, "will_paginate"
      expect( dep_5.name).to eql("will_paginate")
      expect( dep_5.version_requested).to eql("3.0.3")
      expect( dep_5.version_current).to eql("4.0.3")
      expect( dep_5.version_label).to eql("3.0.3")
      expect( dep_5.comperator).to eql("<=")

      dep_6 = fetch_by_name project.dependencies, "gravatar_image_tag"
      expect( dep_6.name).to eql("gravatar_image_tag")
      expect( dep_6.version_requested).to eql("1.1.6")
      expect( dep_6.version_current).to eql("1.1.6")
      expect( dep_6.version_label).to eql("1.1.3")
      expect( dep_6.comperator).to eql(">=")
      expect( dep_6.release).to_not be_nil
      expect( dep_6.release).to be_truthy

      dep_7 = fetch_by_name project.dependencies, "sassy"
      expect( dep_7.name).to eql("sassy")
      expect( dep_7.version_requested).to eql("3.2.9")
      expect( dep_7.version_current).to eql("3.3.9")
      expect( dep_7.version_label).to eql("3.2.0")
      expect( dep_7.comperator).to eql("~>")

      dep_8 = fetch_by_name project.dependencies, "sass-rails"
      expect( dep_8.name).to eql("sass-rails")
      expect( dep_8.version_requested).to eql("3.3.9")
      expect( dep_8.version_current).to eql("3.3.9")
      expect( dep_8.comperator).to eql("~>")
      expect( dep_8.outdated).to be_falsey

      dep_9 = fetch_by_name project.dependencies, "cucumber-rails"
      expect( dep_9.name).to eql("cucumber-rails")
      expect( dep_9.version_requested).to eql("1.0.0")
      expect( dep_9.version_current).to eql("1.0.0")
      expect( dep_9.comperator).to eql("=")

      dep_10 = fetch_by_name project.dependencies, "fastercsv"
      expect( dep_10.name).to eql("fastercsv")
      expect( dep_10.version_requested).to eql("1.0.0")
      expect( dep_10.version_current).to eql("1.0.0")
      expect( dep_10.comperator).to eql("=")

      dep_11 = fetch_by_name project.dependencies, "guard-livereload"
      expect( dep_11.name).to eql("guard-livereload")
      expect( dep_11.version_requested).to eql("1.0.0")
      expect( dep_11.version_current).to eql("1.0.0")
      expect( dep_11.comperator).to eql("=")

      dep_12 = fetch_by_name project.dependencies, "copycopter_client"
      expect( dep_12.name).to eql("copycopter_client")
      expect( dep_12.version_requested).to eql("GITHUB")
      expect( dep_12.version_label).to eql('git://github.com/nmk/copycopter-ruby-client.git')
      expect( dep_12.version_current).to eql("1.0.0")
      expect( dep_12.comperator).to eql("=")

      dep_13 = fetch_by_name project.dependencies, "govkit"
      expect( dep_13.name).to eql("govkit")
      expect( dep_13.version_requested).to eql("PATH")
      expect( dep_13.version_current).to eql("1.0.0")
      expect( dep_13.comperator).to eql("=")

      dep_15 = fetch_by_name project.dependencies, "libnotify"
      expect( dep_15.name).to eql("libnotify")
      expect( dep_15.version_requested).to eql("1.0.0")
      expect( dep_15.version_current).to eql("1.0.0")
      expect( dep_15.comperator).to eql("=")

      dep_16 = fetch_by_name project.dependencies, "growl"
      expect( dep_16.name).to eql("growl")
      expect( dep_16.version_requested).to eql("3.3.3")
      expect( dep_16.version_current).to eql("3.3.3")
      expect( dep_16.comperator).to eql("=")
    end
  end


  describe "fixes for issues" do
    let(:parser){ GemfileParser.new }

    let(:product1){
      FactoryGirl.create(
        :product_with_versions,
        prod_key: 'actioncable',
        name: 'actioncable',
        prod_type: Project::A_TYPE_RUBYGEMS,
        language: Product::A_LANGUAGE_RUBY,
        version: '5.1'
      )
    }

    let(:product2){
      FactoryGirl.create(
        :product_with_versions,
        prod_key: 'actionsupport',
        name: 'actionsupport',
        prod_type: Project::A_TYPE_RUBYGEMS,
        language: Product::A_LANGUAGE_RUBY,
        version: '5.2'
      )

    }

    let(:project_text){
      %Q{
        source "https://rubygems.org/"
        gem "actioncable", "5.1-mingw32"
        gem "actionsupport", "5.2"
      }
    }

    it "removes platform extensions #issue53 " do
      product1.versions << FactoryGirl.build(:product_version, version: '5.1')
      product1.save
      product2.versions << FactoryGirl.build(:product_version, version: '5.2')
      product2.save

      proj = parser.parse_content(project_text)
      expect(proj).to_not be_nil
      expect(proj.projectdependencies.size ).to eq(2)

      dep1 = proj.dependencies[0]

      expect( dep1.name ).to eq(product1[:name])
      expect( dep1.version_requested ).to eq(product1[:version])
      expect( dep1.comperator ).to eq('=')

      dep2 = proj.dependencies[1]
      expect( dep2.name ).to eq( product2[:name] )
      expect( dep2.version_requested ).to eq(product2[:version])
      expect( dep2.comperator ).to eq('=')
    end

  end
end
