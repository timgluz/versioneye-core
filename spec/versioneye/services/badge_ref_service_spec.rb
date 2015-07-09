require 'spec_helper'

describe BadgeRefService do

  describe "fetch ref badge for product" do

    before :all do 
      BadgeRefService.cache.flush
      Badge.delete_all
    end

    it "fetches red badge" do
      product_1 = ProductFactory.create_new "1"
      
      key = "#{product_1.language}:::#{product_1.prod_key}:::ref"
      BadgeRefService.cache.delete key 

      badge = BadgeRefService.badge_for( key )
      badge.should_not be_nil 
      badge.status.should eq('0')
      badge.svg.should_not be_nil 
      BadgeRefService.cache.get(key).should_not be_nil 
      Badge.count.should eq(1)

      BadgeRefService.cache.delete key 

      # Fetch from DB. 
      badge = BadgeRefService.badge_for( key )
      badge.should_not be_nil 
      badge.status.should eq('0')
      badge.svg.should_not be_nil
    end

    it "fetches green badge" do
      product_1 = ProductFactory.create_new "1"
      product_2 = ProductFactory.create_new "2"
      dependency = DependencyFactory.create_new( product_2, product_1 )

      ReferenceService.update_reference product_2.language, product_2.prod_key

      key = "#{product_1.language}:::#{product_1.prod_key}:::ref"
      BadgeRefService.cache.delete key 

      badge = BadgeRefService.badge_for( key )
      badge.should_not be_nil 
      badge.status.should eq('1')
      badge.svg.should_not be_nil 
      BadgeRefService.cache.get(key).should_not be_nil 
      Badge.count.should eq(1)

      BadgeRefService.cache.delete key 

      # Fetch from DB. 
      badge = BadgeRefService.badge_for( key )
      badge.should_not be_nil 
      badge.status.should eq('1')
      badge.svg.should_not be_nil
    end

  end

end
