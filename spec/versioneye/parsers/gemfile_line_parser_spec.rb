require 'spec_helper'

describe GemfileParser do
  let(:parser){ GemfileParser.new }

  describe "extract_repo_name" do
    it "extract correct repo fullname from git url" do
      expect( parser.extract_repo_name('git://github.com/rails/rails') ).to eq('rails/rails')
    end

    it "extracts correct repo fullname and remove git extension" do
      expect( parser.extract_repo_name('git://github.com/rails/rails.git') ).to eq('rails/rails')

    end
  end

  describe "fetch_line_elements" do

    it "returns the right elements" do
      line = "gem 'will_paginate'     , '<= 3.0.3'"
      elements = parser.fetch_line_elements( line )

      expect( elements ).to_not be_nil
      expect( elements.size).to eq(2)
      expect( elements.first).to eql("gem 'will_paginate'")
      expect( elements.last).to  eql("'<= 3.0.3'")
    end

    it "returns the right elements without comments" do
      line = " gem 'will_paginate'     , '<= 3.0.3' # comment "
      elements = parser.fetch_line_elements( line )

      expect( elements).to_not be_nil
      expect( elements.size).to eq(2)
      expect( elements.first).to eql("gem 'will_paginate'")
      expect( elements.last).to  eql("'<= 3.0.3'")
    end

    it "returns the right elements for list items" do
      line = ' gem "will_paginate", "*", platforms: ["osx", "unix"]'
      elements = parser.fetch_line_elements(line)

      expect( elements ).not_to be_nil
      expect( elements.size ).to eq(3)
      expect( elements[0] ).to eq('gem "will_paginate"')
      expect( elements[1] ).to eq('"*"')
      expect( elements[2] ).to eq('platforms: ["osx", "unix"]')
    end
  end

  describe "fetch_gem_name" do

    it "returns nil because its not starting with gem " do
      line = "'will_paginate'     , '<= 3.0.3'"
      elements = parser.fetch_line_elements( line )
      gem_name = parser.fetch_gem_name elements

      expect( gem_name).to be_nil
    end

    it "returns the right gen_name" do
      line = "gem 'will_paginate'     , '<= 3.0.3'"
      elements = parser.fetch_line_elements( line )
      gem_name = parser.fetch_gem_name elements

      expect( gem_name).to_not be_nil
      expect( gem_name).to eql("will_paginate")
    end

  end

  describe "replace comments" do

    it "replaces the comments" do
      line = "'will_paginate'     , '<= 3.0.3'  # test comment   "
      new_line = parser.replace_comments line

      expect( new_line).to_not be_nil
      expect( new_line).to eql("'will_paginate'     , '<= 3.0.3'  ")
    end

  end

  describe "fetch_version" do

    it "returns the right version" do
      line = "gem 'will_paginate'     , '<= 3.0.3'"
      elements = parser.parse_gem_line( line )

      expect( parser.fetch_version( elements )).to eql('<= 3.0.3')
    end

    it "returns the right version" do
      line = " gem 'will_paginate'     , \"> 3.0.3\""
      elements = parser.parse_gem_line( line )

      expect( parser.fetch_version( elements )).to eql('> 3.0.3')
    end

    it "returns the right version for GIT" do
      line = "gem \"copycopter_client\", :git     => \"git://github.com/nmk/copycopter-ruby-client.git\" "
      elements = parser.parse_gem_line( line )

      expect( parser.fetch_version( elements )).to eql('git:git://github.com/nmk/copycopter-ruby-client.git')
    end

    it "returns the right version for PATH" do
      line = "gem 'govkit'           , :path    => '/../vendor/gems'"
      elements = parser.parse_gem_line( line )

      expect( parser.fetch_version( elements )).to eql("path:/../vendor/gems")
    end

    it "returns the right version for Platforms" do
      line = "gem 'therubyracer'     , :platforms => :ruby"
      elements = parser.parse_gem_line( line )

      expect( parser.fetch_version( elements )).to eql("")
    end

    it "returns empty string with multiple platforms" do
      line = "gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :mswin64]"
      elements = parser.parse_gem_line( line )

      expect( parser.fetch_version( elements )).to eql("")
    end

    it "returns correct version with multiple platforms" do
      line = "gem 'tzinfo-data', '= 3.0.3', platforms: [:mingw, :mswin, :x64_mingw, :mswin64]"
      elements = parser.parse_gem_line( line )

      expect( parser.fetch_version( elements )).to eql("= 3.0.3")
    end

    it "returns the right empty string because there is not version, only a group" do
      line = "gem 'rspec',     :group => [:test, :development]"
      elements = parser.fetch_line_elements( line )
      version = parser.parse_gem_line( elements )
      expect( version.nil? ).to be_truthy
    end

  end

  describe "init_project" do

    it "inits the project" do
      project = parser.init_project( "url_url" )

      expect( project).to_not be_nil
      expect( project.url).to eql("url_url")
      expect( project.dependencies).to_not be_nil
      expect( project.dependencies.size).to eq(0)
      expect( project.project_type).to eql(Project::A_TYPE_RUBYGEMS)
      expect( project.language).to     eql(Product::A_LANGUAGE_RUBY)
    end

  end

  describe "init_dependency" do

    it "inits the dependency with product" do
      product = ProductFactory.create_for_gemfile 'rails', '4.0.0'
      gem_name = "rails"
      dependency = parser.init_dependency( product, gem_name )

      expect( dependency).to_not be_nil
      expect( dependency.name).to eql( gem_name )
      expect( dependency.prod_key).to eql(product.prod_key)
      expect( dependency.version_current).to eql(product.version)

      product.remove
    end

    it "inits the dependency without product" do
      product = nil
      gem_name = "rails"
      dependency = parser.init_dependency( product, gem_name )

      expect( dependency).to_not be_nil
      expect( dependency.name).to eql( gem_name )
      expect( dependency.prod_key).to be_nil
      expect( dependency.version_current).to be_nil
    end

  end

  describe "parse_requested_version" do

    it "parses the right version" do
      version_number = "=1.0.0"
      dependency = Projectdependency.new
      product = ProductFactory.create_new 1, :gemfile
      parser.parse_requested_version version_number, dependency, product

      expect( dependency.version_requested).to eql("1.0.0")
    end

    it "parses the right tilde version" do
      version_number = "~>10.10.0"
      dependency = Projectdependency.new
      product = ProductFactory.create_new 1, :gemfile
      product.versions.push Version.new({:version => "10.10.2"})
      product.versions.push Version.new({:version => "10.10.3"})
      product.versions.push Version.new({:version => "10.10.4"})
      product.versions.push Version.new({:version => "9.10.14"})
      product.save
      parser.parse_requested_version version_number, dependency, product

      expect( dependency.version_requested).to eql("10.10.4")
    end

    it "parses the right tilde version" do
      version_number = "~>0.12.2"
      dependency = Projectdependency.new
      product = ProductFactory.create_new 1, :gemfile
      product.versions.push Version.new({:version => "0.12.2"})
      product.versions.push Version.new({:version => "0.12.2.rc1"})
      product.save
      parser.parse_requested_version version_number, dependency, product

      expect( dependency.version_requested).to eql("0.12.2")
    end

  end
end
