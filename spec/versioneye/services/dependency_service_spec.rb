require 'spec_helper'

describe DependencyService do

  describe 'update_dependencies' do

    let(:product){ ProductFactory.create_new(36) }
    let(:user)   { UserFactory.create_new(36) }

    it 'updates the dependencies' do
      product.version.should_not be_nil
      prod_1 = ProductFactory.create_new(37)
      prod_2 = ProductFactory.create_new(38)
      dep_1 = DependencyFactory.create_new product, prod_1
      dep_2 = DependencyFactory.create_new product, prod_2
      dep_1.outdated.should be_nil
      dep_2.outdated.should be_nil

      ver_cache = product.version
      product.version = "0.0.0.0"

      DependencyService.update_dependencies product
      product.all_dependencies.count.should eq(0)

      product.version = ver_cache

      DependencyService.update_dependencies product
      product.all_dependencies.each do |dep|
        dep.outdated.should_not be_nil
        dep.outdated.should be_falsey
      end
    end

  end

  describe 'outdated?' do
    let(:product){FactoryGirl.build(:product,
                                    name: "test1",
                                    prod_key: "test1",
                                    language: "Ruby",
                                    prod_type: Project::A_TYPE_RUBYGEMS)}

    before :each do
    end

    after :each do
      Product.delete_all
    end

    it "is outdated" do
      product.versions << Version.new({version: "1.0" })
      product.save
      dependency = Dependency.new version:      "0.1",
                                  dep_prod_key: product.prod_key,
                                  prod_type:    product.prod_type,
                                  language:     product.language
      DependencyService.outdated?( dependency ).should be_truthy
    end

    it "is not outdated, because it's equal" do
      product.versions << Version.new({:version => "1.0.0"})
      product.version = "1.0.0"
      product.save

      dependency              = Dependency.new
      dependency.version      = product.version
      dependency.dep_prod_key = product.prod_key
      dependency.prod_type    = product.prod_type
      dependency.language     = product.language
      DependencyService.outdated?( dependency ).should be_falsey
    end

    it "is not outdated, because it's a range" do
      product.versions <<  Version.new({:version => "1.0.0"})
      product.version = "1.0.0"
      product.save

      dependency = Dependency.new version: ">= 0.9.0",
                                  dep_prod_key: product.prod_key,
                                  prod_type: product.prod_type,
                                  language: product.language

      DependencyService.outdated?( dependency ).should be_falsey
      dependency.version.should eql(">= 0.9.0")
    end

    it "is not outdated, because it's higher" do
      product = ProductFactory.create_new(1)
      product.versions.push Version.new({ :version => "1.0" })
      product.save

      dependency = Dependency.new version: "100000.2",
                                  language: product.language,
                                  dep_prod_key: product.prod_key

      DependencyService.outdated?( dependency ).should be_falsey
    end

    it "is not outdated, because unknown dep" do
      dependency         = Dependency.new version: "0.1"
      DependencyService.outdated?( dependency ).should be_falsey
    end

  end

  describe "dependencies_outdated?( scope )" do

    it "is not outdated" do
      product           = Product.new
      product.prod_key  = "junit/junit"
      product.name      = "junit"
      product.language  = Product::A_LANGUAGE_JAVA
      product.prod_type = Project::A_TYPE_MAVEN2
      product.save

      prod_1 = ProductFactory.create_new(1)
      prod_2 = ProductFactory.create_new(2)
      prod_3 = ProductFactory.create_new(3)
      prod_4 = ProductFactory.create_new(4)

      DependencyFactory.create_new(product, prod_1)
      DependencyFactory.create_new(product, prod_2)
      DependencyFactory.create_new(product, prod_3)
      DependencyFactory.create_new(product, prod_4)

      product.dependencies(nil).size.should eq(4)
      DependencyService.dependencies_outdated?( product.dependencies(nil) ).should be_falsey
    end

    it "is outdated" do
      product           = Product.new
      product.prod_key  = "junit/junit"
      product.name      = "junit"
      product.language  = Product::A_LANGUAGE_JAVA
      product.prod_type = Project::A_TYPE_MAVEN2
      product.save

      prod_1 = ProductFactory.create_new(1)
      prod_2 = ProductFactory.create_new(2)
      prod_3 = ProductFactory.create_new(3)
      prod_4 = ProductFactory.create_new(4)

      DependencyFactory.create_new(product, prod_1)
      DependencyFactory.create_new(product, prod_2)
      DependencyFactory.create_new(product, prod_3)
      dep_4 = DependencyFactory.create_new(product, prod_4)
      dep_4.version = "0.0"
      dep_4.save

      product.dependencies(nil).size.should eq(4)
      DependencyService.dependencies_outdated?( product.dependencies(nil) ).should be_truthy
    end

  end


  describe "gem_version_parsed" do

    it "returns valid value" do
      product = Product.new({:language => Product::A_LANGUAGE_RUBY, :prod_type => Project::A_TYPE_RUBYGEMS, :prod_key => 'activesupport', :name => 'activesupport'})
      product.versions = Array.new

      product.versions.push(Version.new({:version => "1.0"}))
      product.versions.push(Version.new({:version => "1.1"}))
      product.versions.push(Version.new({:version => "1.2"}))
      product.versions.push(Version.new({:version => "2.0"}))
      product.save.should be_truthy

      dependency = Dependency.new
      dependency.language = product.language
      dependency.version = "~> 1.0"
      dependency.dep_prod_key = product.prod_key

      DependencyService.update_parsed_version dependency
      dependency.parsed_version.should eql("1.2")

      product.remove
    end

    it "returns valid value" do
      product = Product.new({:name => "test", :prod_key => "huj_buuuuu", :language => Product::A_LANGUAGE_RUBY, :prod_type => Project::A_TYPE_RUBYGEMS})
      product.versions = Array.new

      product.versions.push(Version.new({:version => "1.2"}))
      product.versions.push(Version.new({:version => "2.0"}))
      product.versions.push(Version.new({:version => "2.2.1"}))
      product.versions.push(Version.new({:version => "2.2.2"}))
      product.versions.push(Version.new({:version => "2.2.9"}))
      product.versions.push(Version.new({:version => "2.3"}))
      product.save.should be_truthy

      dependency = Dependency.new
      dependency.version = "~> 2.2"
      dependency.dep_prod_key = product.prod_key
      dependency.language = product.language

      DependencyService.update_parsed_version dependency
      dependency.parsed_version.should eql("2.3")

      dependency.version = "~> 2.0"
      dependency.dep_prod_key = product.prod_key

      DependencyService.update_parsed_version dependency
      dependency.parsed_version.should eql("2.3")

      product.remove
    end

  end

 describe "cocoapods_version_parsed" do

    it "returns valid value" do
      product = Product.new({:name => 'test', :prod_key => 'test', :language => Product::A_LANGUAGE_OBJECTIVEC, :prod_type => Project::A_TYPE_COCOAPODS })
      product.versions = Array.new

      product.versions.push(Version.new({:version => "1.0"}))
      product.versions.push(Version.new({:version => "1.1"}))
      product.versions.push(Version.new({:version => "1.2"}))
      product.versions.push(Version.new({:version => "2.0"}))
      product.save.should be_truthy

      dependency = Dependency.new
      dependency.language = product.language
      dependency.version = "~> 1.0"
      dependency.dep_prod_key = product.prod_key

      DependencyService.update_parsed_version dependency
      dependency.parsed_version.should eql("1.2")

      product.remove
    end

    it "returns valid value" do
      product = Product.new({:name => 'test', :prod_key => 'test', :language => Product::A_LANGUAGE_OBJECTIVEC, :prod_type => Project::A_TYPE_COCOAPODS })
      product.versions = Array.new

      product.versions.push(Version.new({:version => "1.2"}))
      product.versions.push(Version.new({:version => "2.0"}))
      product.versions.push(Version.new({:version => "2.2.1"}))
      product.versions.push(Version.new({:version => "2.2.2"}))
      product.versions.push(Version.new({:version => "2.2.9"}))
      product.versions.push(Version.new({:version => "2.3"}))

      product.save

      dependency = Dependency.new({:prod_type => Project::A_TYPE_COCOAPODS})
      dependency.version = "~> 2.2"
      dependency.dep_prod_key = product.prod_key
      dependency.language = product.language
      DependencyService.update_parsed_version dependency
      dependency.parsed_version.should eql("2.3")

      dependency.version = "~> 2.0"
      dependency.dep_prod_key = product.prod_key

      DependencyService.update_parsed_version dependency
      dependency.parsed_version.should eql("2.3")

      product.remove
    end

  end


  describe "packagist_version_parsed" do

    it "returns valid value" do
      product = Product.new({:name => 'test', :prod_key => 'test', :language => Product::A_LANGUAGE_PHP, :prod_type => Project::A_TYPE_COMPOSER })
      product.versions = Array.new

      product.versions.push(Version.new({:version => "1.0"}))
      product.versions.push(Version.new({:version => "1.1"}))
      product.versions.push(Version.new({:version => "1.2"}))
      product.versions.push(Version.new({:version => "2.0"}))
      product.save.should be_truthy

      dependency = Dependency.new({:prod_type => Project::A_TYPE_COMPOSER})
      dependency.language = product.language
      dependency.version = "~1.0"
      dependency.dep_prod_key = product.prod_key
      DependencyService.update_parsed_version dependency
      dependency.parsed_version.should eql("1.2")

      product.remove
    end

    it "returns valid value" do
      product = Product.new({:name => 'test', :prod_key => 'test', :language => Product::A_LANGUAGE_PHP, :prod_type => Project::A_TYPE_COMPOSER })
      product.versions = Array.new

      product.versions.push(Version.new({:version => "1.2"}))
      product.versions.push(Version.new({:version => "2.0"}))
      product.versions.push(Version.new({:version => "2.2.1"}))
      product.versions.push(Version.new({:version => "2.2.2"}))
      product.versions.push(Version.new({:version => "2.2.9"}))
      product.versions.push(Version.new({:version => "2.3"}))
      product.versions.push(Version.new({:version => "3.0"}))
      product.save

      dependency = Dependency.new({:prod_type => Project::A_TYPE_COMPOSER})
      dependency.language = product.language
      dependency.version = "~2.2"
      dependency.dep_prod_key = product.prod_key
      DependencyService.update_parsed_version dependency
      dependency.parsed_version.should eql("2.3")

      product.remove
    end

  end

  describe "npm_version_parsed" do

    it "returns valid value" do
      product = Product.new({:name => 'test', :prod_key => 'test', :language => Product::A_LANGUAGE_NODEJS, :prod_type => Project::A_TYPE_NPM })
      product.versions = Array.new

      product.versions.push(Version.new({:version => "1.0"}))
      product.versions.push(Version.new({:version => "1.1"}))
      product.versions.push(Version.new({:version => "1.2"}))
      product.versions.push(Version.new({:version => "2.0"}))
      product.save.should be_truthy

      dependency = Dependency.new({:prod_type => Project::A_TYPE_NPM})
      dependency.language = product.language
      dependency.version = "~1.0"
      dependency.dep_prod_key = product.prod_key
      DependencyService.update_parsed_version dependency
      dependency.parsed_version.should eql("1.2")

      product.remove
    end

  end

end
