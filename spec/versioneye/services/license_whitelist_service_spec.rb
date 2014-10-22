require 'spec_helper'

describe LicenseWhitelistService do

  describe 'index' do

    it 'returns the list for the given user' do
      user = UserFactory.create_new 1
      lwl = LicenseWhitelist.new({:name => 'OkForMe', :user_id => user.id})
      lwl.save.should be_truthy
      lwl = LicenseWhitelist.new({:name => 'HubaBuba', :user_id => 'asgfasga'})
      lwl.save.should be_truthy
      lwls = LicenseWhitelistService.index user
      lwls.should_not be_nil
      lwls.first.name.should eq("OkForMe")
      lwls.count.should == 1
    end

    it 'returns the all whitelists in enterprise env' do
      user  = UserFactory.create_new 1
      admin = UserFactory.create_new 2

      lwl = LicenseWhitelist.new({:name => 'OkForMe', :user_id => admin.id})
      lwl.save.should be_truthy
      lwl = LicenseWhitelist.new({:name => 'HubaBuba', :user_id => admin.id})
      lwl.save.should be_truthy

      Settings.instance.instance_variable_set(:@environment, 'enterprise')

      lwls = LicenseWhitelistService.index user
      lwls.should_not be_nil
      lwls.count.should == 2
      lwls.first.name.should eq("OkForMe")

      Settings.instance.instance_variable_set(:@environment, 'test')
    end

  end

  describe 'fetch_by' do

    it 'returns the list for the given user' do
      user = UserFactory.create_new 1
      lwl = LicenseWhitelist.new({:name => 'OkForMe', :user_id => user.id})
      lwl.save.should be_truthy
      lwl = LicenseWhitelist.new({:name => 'HubaBuba', :user_id => 'asgfasga'})
      lwl.save.should be_truthy
      lw = LicenseWhitelistService.fetch_by user, 'OkForMe'
      lw.should_not be_nil
      lw.name.should eq('OkForMe')
    end

    it 'returns the list with given name, even if user is not owner of the list (Enterprise env)' do
      user  = UserFactory.create_new 1
      admin = UserFactory.create_new 2

      lwl = LicenseWhitelist.new({:name => 'OkForMe', :user_id => admin.id})
      lwl.save.should be_truthy
      lwl = LicenseWhitelist.new({:name => 'HubaBuba', :user_id => admin.id})
      lwl.save.should be_truthy

      Settings.instance.instance_variable_set(:@environment, 'enterprise')

      lw = LicenseWhitelistService.fetch_by user, 'OkForMe'
      lw.should_not be_nil
      lw.name.should eq("OkForMe")

      Settings.instance.instance_variable_set(:@environment, 'test')
    end

  end

end
