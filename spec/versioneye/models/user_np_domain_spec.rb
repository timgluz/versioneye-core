require 'spec_helper'

describe User do

  describe "save with np domain" do

    it "saves a new user with np domain" do
      ActionMailer::Base.deliveries.clear
      NpDomain.new.save.should be_truthy

      email = "daniele@etna-alternance.net"
      user = User.new
      user.fullname = "Daniele sluijters"
      user.username = "sluijters"
      user.email = email
      user.password = "password"
      user.salt = "salt"
      user.terms = true
      user.datenerhebung = true
      user.save.should be_truthy
      db_user = User.find_by_email( email )
      db_user.should_not be_nil
      db_user.free_private_projects.should == 50
      ActionMailer::Base.deliveries.size.should == 1
      user.remove
    end

    it "saves a new user without np domain" do
      ActionMailer::Base.deliveries.clear
      email = "daniele@etna-alternance.net"
      user = User.new
      user.fullname = "Daniele sluijters"
      user.username = "sluijters"
      user.email = email
      user.password = "password"
      user.salt = "salt"
      user.terms = true
      user.datenerhebung = true
      user.save.should be_truthy
      db_user = User.find_by_email( email )
      db_user.should_not be_nil
      db_user.free_private_projects.should == 0
      ActionMailer::Base.deliveries.size.should == 0
      user.remove
    end

  end

end
