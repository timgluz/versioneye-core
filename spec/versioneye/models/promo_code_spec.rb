require 'spec_helper'

describe PromoCode do

  describe "by_name" do

    it "returns nil for nil" do
      PromoCode.by_name(nil).should be_nil
    end

    it "returns promo tada for nil" do
      promo_name = "changelog_weekly_2"
      now        = DateTime.now
      future     = now + 7.days
      pc         = PromoCode.new({:name => promo_name, :free_private_projects => 3, :end_date => future})
      pc.save!.should be_true
      tada = PromoCode.by_name(promo_name)
      tada.should_not be_nil
      tada.name.should eq(promo_name)
      tada.free_private_projects.should eq(3)
      tada.redeemed.should eq(0)
      tada.end_date.should_not be_nil
      tada.end_date.should eq(future)
    end

  end

  describe "valid?" do

    it "is valid" do
      promo = PromoCode.new({:name => "changelog_weekly_1", :free_private_projects => 3})
      promo.save
      promo.is_valid?().should be_true
    end

    it "is not valid" do
      past = DateTime.now - 7.days
      promo = PromoCode.new({:name => "changelog_weekly_1", :free_private_projects => 3, :end_date => past})
      promo.save
      promo.is_valid?().should be_false
    end

  end

  describe "redeem!" do

    it "remeems" do
      promo = PromoCode.new({:name => "changelog_weekly_2", :free_private_projects => 3})
      promo.save
      promo.redeemed.should eq(0)
      promo.redeem!
      promo.redeemed.should eq(1)
      promo.redeem!
      promo.redeemed.should eq(2)
    end

  end

end
