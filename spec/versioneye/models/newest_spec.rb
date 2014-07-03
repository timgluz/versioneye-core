require 'spec_helper'

describe Newest do


  describe "since_to" do
    it "should return all newest todays packages" do
      create_today_products

      rows = Newest.since_to(0.days.ago.at_midnight, -1.days.ago.at_midnight)
      rows.count.should == 13
    end

    it "should return all yesterdays packages" do
      create_yesterday_products

      rows = Newest.since_to(1.days.ago.at_midnight, 0.days.ago.at_midnight)
      rows.count.should == 17
    end
  end

  def create_today_products
    newests = []
    (0..12).each do |s|
      name = FactoryGirl.generate(:product_name_generator)
      newest = Newest.new({:name => name, :prod_key => name, :language => 'Ruby', :prod_type => 'gem', :version => Random.rand(1..99), created_at: Date.today.at_midnight })
      newest.save
      newests << newest
    end
    newests
  end

  def create_yesterday_products
    newests = []
    (20..36).each do |s|
      name = FactoryGirl.generate(:product_name_generator)
      newest = Newest.new({:name => name, :prod_key => name, :language => 'Ruby', :prod_type => 'gem', :version => Random.rand(1..99), created_at: 1.days.ago.at_midnight })
      newest.save
      newests << newest
    end
    newests
  end


end
