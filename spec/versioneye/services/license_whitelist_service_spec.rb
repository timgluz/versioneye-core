require 'spec_helper'

describe LicenseWhitelistService do

  describe 'enterprise_permission' do

    it 'returns false because user is nil' do
      LicenseWhitelistService.enterprise_permission(nil).should be_falsy 
    end
    it 'returns false because user is not admin' do
      user = UserFactory.create_new 1
      user.admin = false 
      user.fetch_or_create_permissions.lwl = false 
      LicenseWhitelistService.enterprise_permission(user).should be_falsy 
    end
    it 'returns true because user is admin' do
      user = UserFactory.create_new 1
      user.admin = true  
      user.fetch_or_create_permissions.lwl = false 
      LicenseWhitelistService.enterprise_permission(user).should be_truthy
    end
    it 'returns true because user has lwl permission' do
      user = UserFactory.create_new 1
      user.admin = false 
      user.fetch_or_create_permissions.lwl = true 
      LicenseWhitelistService.enterprise_permission(user).should be_truthy
    end

  end

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

  describe 'create_for' do

    it 'create a list for a user' do
      user = UserFactory.create_new 1
      resp = LicenseWhitelistService.create user, 'SuperList'
      resp.should be_truthy
    end

    it 'returns the list with given name, even if user is not owner of the list (Enterprise env)' do
      user  = UserFactory.create_new 1
      admin = UserFactory.create_new 2
      admin.admin = true
      admin.save

      Settings.instance.instance_variable_set(:@environment, 'enterprise')

      resp = LicenseWhitelistService.create user, 'SuperList'
      resp.should be_falsy

      resp = LicenseWhitelistService.create admin, 'SuperList'
      resp.should be_truthy

      Settings.instance.instance_variable_set(:@environment, 'test')
    end

  end

  describe 'add' do

    it 'add new license to list for a user' do
      user = UserFactory.create_new 1
      resp = LicenseWhitelistService.create user, 'SuperList'
      resp.should be_truthy
      resp = LicenseWhitelistService.add user, 'SuperList', 'MIT'
      resp.should be_truthy
      list = LicenseWhitelistService.fetch_by user, 'SuperList'
      list.license_elements.count.should eq(1)
      list.license_elements.first.name.should eq('MIT')
    end

    it 'add new license to list for user (Enterprise env)' do
      user  = UserFactory.create_new 1
      admin = UserFactory.create_new 2
      admin.admin = true
      admin.save

      Settings.instance.instance_variable_set(:@environment, 'enterprise')

      resp = LicenseWhitelistService.create admin, 'SuperList'
      resp.should be_truthy

      resp = LicenseWhitelistService.add user, 'SuperList', 'MIT'
      resp.should be_falsy

      resp = LicenseWhitelistService.add admin, 'SuperList', 'MIT'
      resp.should be_truthy

      Settings.instance.instance_variable_set(:@environment, 'test')
    end

  end

  describe 'default' do

    it 'sets the default' do
      user = UserFactory.create_new 1
      resp = LicenseWhitelistService.create user, 'SuperList'
      resp.should be_truthy
      resp = LicenseWhitelistService.create user, 'MyList'
      resp.should be_truthy
      resp = LicenseWhitelistService.create user, 'YourList'
      resp.should be_truthy

      LicenseWhitelist.count.should eq(3)
      LicenseWhitelist.all.each do |lwl| 
        lwl.default.should be_falsy
      end

      LicenseWhitelistService.default user, 'MyList'
      lwl = LicenseWhitelist.fetch_by user, 'MyList'
      lwl.default.should be_truthy
      lwl = LicenseWhitelist.fetch_by user, 'SuperList'
      lwl.default.should be_falsy
      lwl = LicenseWhitelist.fetch_by user, 'YourList'
      lwl.default.should be_falsy
    end

  end

  describe 'fetch_default_id' do

    it 'returns nil because there is no default' do
      user = UserFactory.create_new 1
      resp = LicenseWhitelistService.create user, 'SuperList'
      resp.should be_truthy

      LicenseWhitelist.count.should eq(1)
      LicenseWhitelistService.fetch_default_id(user).should be_nil 
    end

    it 'returns the default_id' do
      user = UserFactory.create_new 1
      resp = LicenseWhitelistService.create user, 'SuperList'
      resp.should be_truthy
      resp = LicenseWhitelistService.create user, 'MyList'
      resp.should be_truthy

      LicenseWhitelistService.default user, 'MyList'
      lwl = LicenseWhitelist.fetch_by user, 'MyList'

      LicenseWhitelistService.fetch_default_id(user).should eq(lwl.id.to_s)
    end

  end

  describe 'remove' do

    it 'remove license from list for a user' do
      user = UserFactory.create_new 1

      resp = LicenseWhitelistService.create user, 'SuperList'
      resp = LicenseWhitelistService.add user, 'SuperList', 'MIT'
      list = LicenseWhitelistService.fetch_by user, 'SuperList'
      list.license_elements.count.should eq(1)
      resp = LicenseWhitelistService.remove user, 'SuperList', 'MIT'
      resp.should be_truthy
      list = LicenseWhitelistService.fetch_by user, 'SuperList'
      list.license_elements.count.should eq(0)
    end

    it 'remove license from list for a user (Enterprise env)' do
      user  = UserFactory.create_new 1
      admin = UserFactory.create_new 2
      admin.admin = true
      admin.save

      Settings.instance.instance_variable_set(:@environment, 'enterprise')

      resp = LicenseWhitelistService.create admin, 'SuperList'
      resp = LicenseWhitelistService.add admin, 'SuperList', 'MIT'
      list = LicenseWhitelistService.fetch_by admin, 'SuperList'
      list.license_elements.count.should eq(1)

      resp = LicenseWhitelistService.remove user, 'SuperList', 'MIT'
      resp.should be_falsy

      list = LicenseWhitelistService.fetch_by admin, 'SuperList'
      list.license_elements.count.should eq(1)

      resp = LicenseWhitelistService.remove admin, 'SuperList', 'MIT'
      resp.should be_truthy

      list = LicenseWhitelistService.fetch_by admin, 'SuperList'
      list.license_elements.count.should eq(0)

      Settings.instance.instance_variable_set(:@environment, 'test')
    end

  end

end
