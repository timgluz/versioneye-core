require 'spec_helper'

describe ProductService do

  let( :product ) { Product.new }


  describe 'search' do

    it 'finds the product' do
      prod = ProductFactory.create_new(34)
      prod.save
      EsProduct.reset
      EsProduct.index_all
      results = ProductService.search prod.name
      results.count.should eq(1)
    end

  end


  describe "follow" do

    let(:product){ ProductFactory.create_new(34) }
    let(:user)   { UserFactory.create_new(34) }

    it "creates a follower" do
      response = ProductService.follow product.language, product.prod_key, user
      response.should be_true
      prod = Product.fetch_product( product.language, product.prod_key )
      prod.users.count.should eq(1)
      prod.followers.should eq(1)
      subscribers = prod.users
      subscribers.size.should eq(1)
      sub_user = subscribers.first
      sub_user.email.should eql(user.email)
    end

  end

  describe 'unfollow' do

    let(:product){ ProductFactory.create_new(35) }
    let(:user)   { UserFactory.create_new(35) }

    it "unfollows successfully" do
      response = ProductService.follow   product.language, product.prod_key, user
      response.should be_true
      response = ProductService.unfollow product.language, product.prod_key, user
      response.should be_true
      prod = Product.fetch_product( product.language, product.prod_key )
      prod.followers.should eq(0)
      subscribers = prod.users
      subscribers.size.should eq(0)
      prod.users.count.should eq(0)
    end

    it "destroys returns error because product does not exist" do
      unfollow = ProductService.unfollow "lang", "_does_not_exist_", user
      unfollow.should be_false
    end

  end

  describe "update_version_data" do

    it "returns the one" do
      product.versions = Array.new
      product.versions.push( Version.new( { :version => "1.0" } ) )
      ProductService.update_version_data( product )
      product.version.should eql("1.0")
    end

    it "returns the highest stable" do
      product.versions = Array.new
      product.versions.push( Version.new( { :version => "1.0"     } ) )
      product.versions.push( Version.new( { :version => "1.1"     } ) )
      product.versions.push( Version.new( { :version => "1.2-dev" } ) )
      ProductService.update_version_data( product )
      product.version.should eql("1.1")
    end

    it "returns the highest unststable because there is no stable" do
      product.versions = Array.new
      product.versions.push( Version.new( { :version => "1.0-beta" } ) )
      product.versions.push( Version.new( { :version => "1.1-beta" } ) )
      product.versions.push( Version.new( { :version => "1.2-dev"  } ) )
      ProductService.update_version_data( product )
      product.version.should eql("1.2-dev")
    end

  end

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

      ProductService.update_dependencies product
      product.all_dependencies.count.should eq(0)

      product.version = ver_cache

      ProductService.update_dependencies product
      product.all_dependencies.each do |dep|
        dep.outdated.should_not be_nil
        dep.outdated.should be_false
      end
    end

  end

  describe 'update_average_release_time' do

    let(:product){ ProductFactory.create_new(37) }
    let(:user)   { UserFactory.create_new(37) }

    it 'returns the average release time' do
      version_1 = Version.new :released_at => DateTime.new(2014, 01, 01)
      version_2 = Version.new :released_at => DateTime.new(2014, 01, 03)
      version_3 = Version.new :released_at => DateTime.new(2014, 01, 05)
      product.versions = [version_1, version_2, version_3]
      arl = ProductService.update_average_release_time product
      arl.should eq(1)
    end

    it 'returns the estimated release time' do
      product[:average_release_time].should be_nil
      version_1 = Version.new :created_at => DateTime.new(2014, 01, 01)
      version_2 = Version.new :created_at => DateTime.new(2014, 02, 01)
      version_3 = Version.new :created_at => DateTime.new(2014, 03, 02)
      product.versions = [version_1, version_2, version_3]
      arl = ProductService.update_average_release_time product
      product[:average_release_time].should eq(20)
      arl.should eq(20)
    end

  end

  describe 'fetch_product' do

    it 'returns nil' do
      ProductService.fetch_product("PHP", "not_exist").should be_nil
    end

    it 'returns the java product as fallback for a non existing clojure product' do
      prod_1 = ProductFactory.create_for_maven('junit', 'junit', '1.0.0')
      prod_1.save
      prod = ProductService.fetch_product(Product::A_LANGUAGE_CLOJURE, "junit/junit")
      prod.should_not be_nil
      prod.language.should eq(Product::A_LANGUAGE_JAVA)
    end

    it 'returns the java product' do
      prod_1 = ProductFactory.create_for_maven('junit', 'junit', '1.0.0')
      prod_1.save
      prod = ProductService.fetch_product(Product::A_LANGUAGE_JAVA, "junit/junit")
      prod.should_not be_nil
      prod.language.should eq(Product::A_LANGUAGE_JAVA)
    end

    it 'returns the clojure product' do
      prod_1 = ProductFactory.create_for_maven('junit', 'junit', '1.0.0')
      prod_1.language = Product::A_LANGUAGE_CLOJURE
      prod_1.save
      prod = ProductService.fetch_product(Product::A_LANGUAGE_CLOJURE, "junit/junit")
      prod.should_not be_nil
      prod.language.should eq(Product::A_LANGUAGE_CLOJURE)
    end

    it 'returns the product with updated version' do
      prod_1 = ProductFactory.create_for_maven('junit', 'junit', '1.0.0')
      prod_1.version = nil
      prod_1.save
      prod = ProductService.fetch_product(Product::A_LANGUAGE_JAVA, "junit/junit")
      prod.should_not be_nil
      prod.version.should_not be_nil
      pr = Product.fetch_product Product::A_LANGUAGE_JAVA, "junit/junit"
      pr.version.should_not be_nil
    end

    it 'returns the product with updated outdated' do
      prod = ProductFactory.create_for_maven('junit', 'junit', '1.0.0')

      version_1 = Version.new :created_at => DateTime.new(2014, 01, 01)
      version_2 = Version.new :created_at => DateTime.new(2014, 02, 01)
      version_3 = Version.new :created_at => DateTime.new(2014, 03, 02)
      prod.versions = [version_1, version_2, version_3]
      prod.save

      old_version = prod.version

      prod_1 = ProductFactory.create_new(37)
      prod_2 = ProductFactory.create_new(38)
      dep_1 = DependencyFactory.create_new prod, prod_1
      dep_2 = DependencyFactory.create_new prod, prod_2

      prod.version = "0.0.0.0"

      prod_3 = ProductFactory.create_new(39)
      prod_4 = ProductFactory.create_new(40)
      dep_3 = DependencyFactory.create_new prod, prod_3
      dep_4 = DependencyFactory.create_new prod, prod_4

      prod = ProductService.fetch_product(Product::A_LANGUAGE_JAVA, "junit/junit")
      prod.should_not be_nil
      prod[:average_release_time].should eq(20)

      deps = prod.all_dependencies
      deps.should_not be_nil
      deps.count.should eq(2)
      deps.each do |dep|
        dep.outdated.should_not be_nil
      end

      # This one is not yet updated
      dep_3_r = Dependency.find dep_3.id
      dep_3_r.outdated.should be_nil

      prod = ProductService.fetch_product(Product::A_LANGUAGE_JAVA, "junit/junit", "0.0.0.0")
      prod.version.should eq('0.0.0.0')
      deps = prod.all_dependencies
      deps.count.should eq(2)
      deps.first.id.to_s.should eq(dep_3.id.to_s)
    end

  end


  describe '' do

    let(:prod_1) { ProductFactory.create_new(34) }
    let(:prod_2) { ProductFactory.create_new(35) }
    let(:prod_3) { ProductFactory.create_new(36) }
    let(:user)   { UserFactory.create_new(34) }

    it 'updates the meta data' do
      prod_1.save
      prod_2.save
      prod_3.save
      user.save

      dependency = Dependency.new({ :language => prod_2.language,
        :prod_key => prod_2.prod_key, :prod_version => prod_2.version,
        :dep_prod_key => prod_1.prod_key, :version => prod_1.version})
      dependency.save

      Product.where(:followers => 1).count.should == 0
      Product.where(:used_by_count => 1).count.should == 0

      ProductService.follow prod_1.language, prod_1.prod_key, user
      ProductService.follow prod_2.language, prod_2.prod_key, user

      ProductService.update_meta_data_global

      Product.where(:followers => 1).count.should == 2
      Product.where(:used_by_count => 1).count.should == 1


    end

  end


  describe 'update_followers' do

    let(:prod_1) { ProductFactory.create_new(34) }
    let(:prod_2) { ProductFactory.create_new(35) }
    let(:prod_3) { ProductFactory.create_new(36) }
    let(:user)   { UserFactory.create_new(34) }

    it 'updates the followers' do
      prod_1.save
      prod_2.save
      prod_3.save
      user.save

      Product.where(:followers => 1).count.should == 0

      ProductService.follow prod_1.language, prod_1.prod_key, user
      ProductService.follow prod_2.language, prod_2.prod_key, user

      ProductService.update_followers

      Product.where(:followers => 1).count.should == 2
    end

  end


  describe "update_used_by_count" do

    let(:product ) { Product.new(:language => Product::A_LANGUAGE_RUBY, :prod_key => "funny_bunny", :name => 'funny_bunny', :version => "1.0.0") }
    let(:version1) {FactoryGirl.build(:product_version, version: "0.0.1")}
    let(:version2) {FactoryGirl.build(:product_version, version: "0.0.2")}
    let(:version3) {FactoryGirl.build(:product_version, version: "0.1")}

    it "returns 0 because there are no deps" do
      product_1 = ProductFactory.create_new 1
      product_1.save
      described_class.update_used_by_count product_1
      product_1.used_by_count.should eq(0)
    end

    it "returns 1 because there is 1 dep" do
      product_1 = ProductFactory.create_new 1
      product_2 = ProductFactory.create_new 2
      dependency = Dependency.new({ :language => product_2.language,
        :prod_key => product_2.prod_key, :prod_version => product_2.version,
        :dep_prod_key => product_1.prod_key, :version => product_1.version})
      dependency.save
      product_1.save
      described_class.update_used_by_count product_1
      product_1.used_by_count.should eq(1)
    end

    it "returns still 1 because there are 2 deps from 1 product" do
      product_1 = ProductFactory.create_new 1
      product_2 = ProductFactory.create_new 2
      dependency = Dependency.new({ :language => product_2.language,
        :prod_key => product_2.prod_key, :prod_version => product_2.version,
        :dep_prod_key => product_1.prod_key, :version => product_1.version})
      dependency.save
      dependency2 = Dependency.new({ :language => product_2.language,
        :prod_key => product_2.prod_key, :prod_version => "dev-master",
        :dep_prod_key => product_1.prod_key, :version => product_1.version})
      dependency2.save
      product_1.save
      described_class.update_used_by_count product_1
      product_1.used_by_count.should eq(1)
    end

    it "returns 2 because there are 2 deps" do
      product_1 = ProductFactory.create_new 1
      product_2 = ProductFactory.create_new 2
      product_3 = ProductFactory.create_new 3
      dependency = Dependency.new({ :language => product_2.language,
        :prod_key => product_2.prod_key, :prod_version => product_2.version,
        :dep_prod_key => product_1.prod_key, :version => product_1.version})
      dependency.save
      dependency2 = Dependency.new({ :language => product_3.language,
        :prod_key => product_3.prod_key, :prod_version => product_3.version,
        :dep_prod_key => product_1.prod_key, :version => product_1.version})
      dependency2.save
      product_1.save
      described_class.update_used_by_count product_1
      product_1.used_by_count.should eq(2)
    end

  end


  describe 'update_followers_for' do

    let(:product){ ProductFactory.create_new(34) }
    let(:user)   { UserFactory.create_new(34) }

    it 'updates the follower count' do
      Product.count.should == 0
      response = ProductService.follow product.language, product.prod_key, user
      response.should be_true

      product = Product.first
      product.followers = 0
      product.save.should be_true

      Product.count.should == 1
      prod = Product.first
      prod.followers.should == 0

      ProductService.update_followers_for prod
      prod = Product.first
      prod.followers.should == 1
    end

  end

  describe 'remove' do

    it 'removes' do
      prod_1 = ProductFactory.create_new(37)
      prod_1.save.should be_true
      Product.count.should == 1
      ProductService.remove prod_1
      Product.count.should == 0
    end

  end

end
