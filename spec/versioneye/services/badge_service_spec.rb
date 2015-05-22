require 'spec_helper'

describe BadgeService do

  describe "fetch_badge for product" do

    before :all do 
      BadgeService.cache.flush
      Badge.delete_all
    end

    it "fetches green badge" do
      product_1 = ProductFactory.create_new "1"
      product_2 = ProductFactory.create_new "2"
      dependency = DependencyFactory.create_new( product_2, product_1 )

      key = "#{product_2.language}:::#{product_2.prod_key}:::#{product_2.version}"
      BadgeService.cache.delete key 

      badge = BadgeService.badge_for( key )
      badge.should_not be_nil 
      badge.status.should eq('up_to_date')
      badge.svg.should_not be_nil 
      BadgeService.cache.get(key).should_not be_nil 
      Badge.count.should eq(1)

      BadgeService.cache.delete key 

      # Fetch from DB. 
      badge = BadgeService.badge_for( key )
      badge.should_not be_nil 
      badge.status.should eq('up_to_date')
      badge.svg.should_not be_nil
    end

    it "fetches yellow badge" do
      product_1 = ProductFactory.create_new "1"
      product_1.add_version '1000000.0.0'
      product_1.save 
      product_2 = ProductFactory.create_new "2"
      dependency = DependencyFactory.create_new( product_2, product_1 )

      key = "#{product_2.language}:::#{product_2.prod_key}:::#{product_2.version}"
      BadgeService.cache.delete key 

      badge = BadgeService.badge_for( key )
      badge.should_not be_nil 
      badge.status.should eq('out_of_date')
      badge.svg.should_not be_nil
      BadgeService.cache.get(key).should_not be_nil 
    end
    
    it "fetches unknown badge" do
      key = "nan:::nam:::1"
      BadgeService.cache.delete key 

      badge = BadgeService.badge_for( key )
      badge.should_not be_nil 
      badge.status.should eq('unknown')
      badge.svg.should_not be_nil 
      BadgeService.cache.get(key).should_not be_nil 
    end

    it "fetches none badge" do
      product_1 = ProductFactory.create_new "1"
      key = "#{product_1.language}:::#{product_1.prod_key}:::#{product_1.version}"
      BadgeService.cache.delete key 

      badge = BadgeService.badge_for( key )
      badge.svg.should eq(Badge::A_NONE_SVG)
      badge.status.should eq('none')
      BadgeService.cache.get(key).should_not be_nil 
    end

  end

  describe "fetch_badge for project" do

    before :all do 
      BadgeService.cache.flush
    end

    it "fetches green badge" do
      user = UserFactory.create_new 
      product_1 = ProductFactory.create_new "1"
      project = ProjectFactory.create_new user 
      dep = ProjectdependencyFactory.create_new project, product_1
    
      key = project.ids 
      BadgeService.cache.delete key 

      badge = BadgeService.badge_for( key )
      badge.svg.should eq(Badge::A_UPTODATE_SVG)
      badge.status.should eq('up_to_date')
      BadgeService.cache.get(key).should_not be_nil 
      Badge.count.should eq(1)

      BadgeService.cache.delete key 

      # Fetch from DB. 
      badge = BadgeService.badge_for( key )
      badge.should_not be_nil 
      badge.status.should eq('up_to_date')
      badge.svg.should_not be_nil
      Badge.count.should eq(1)
    end

    it "fetches yellow badge" do
      user = UserFactory.create_new 
      product_1 = ProductFactory.create_new "1"
      product_1.add_version '1000.0.0'
      product_1.save 
      project = ProjectFactory.create_new user 
      dep = ProjectdependencyFactory.create_new project, product_1
      dep.version_requested = '0'
      dep.save 
    
      key = project.ids 
      BadgeService.cache.delete key 

      badge = BadgeService.badge_for( key )
      badge.status.should eq('out_of_date')
      BadgeService.cache.get(key).should_not be_nil 
      Badge.count.should eq(1)
    end

    it "fetches yellow - green badge" do
      user = UserFactory.create_new 
      product_1 = ProductFactory.create_new "1"
      product_1.add_version '1000.0.0'
      product_1.version = '1000.0.0'
      product_1.save 
      project = ProjectFactory.create_new user 
      dep = ProjectdependencyFactory.create_new project, product_1
      dep.version_requested = '0'
      dep.save 
    
      key = project.ids 
      BadgeService.cache.delete key 

      badge = BadgeService.badge_for( key )
      badge.status.should eq('out_of_date')
      BadgeService.cache.get(key).should_not be_nil 
      Badge.count.should eq(1)

      BadgeService.cache.delete key 
      
      dep.version_requested = product_1.version
      dep.outdated = false
      dep.save.should be_truthy

      badge.updated_at = 2.days.ago 
      badge.save.should be_truthy

      worker = Thread.new{ DependencyBadgeWorker.new.work }
      badge = BadgeService.badge_for( key )
      badge.status.should eq('out_of_date')
      sleep 3
      badge = BadgeService.badge_for( key )
      badge.status.should eq('up_to_date')
      worker.exit 
      Badge.count.should eq(1)
    end

    it "fetches unknown badge" do
      key = "nan" 
      BadgeService.cache.delete key 

      badge = BadgeService.badge_for( key )
      badge.should_not be_nil 
      badge.status.should eq('unknown')
      BadgeService.cache.get(key).should_not be_nil 
      Badge.count.should eq(1)
    end

  end

end
