require 'spec_helper'

describe ComponentWhitelistService do

  describe 'index' do

    it 'returns the list for the given user' do
      user = UserFactory.create_new 1
      cwl = ComponentWhitelist.new({:name => 'OkForMe', :user_id => user.id})
      expect( cwl.save ).to be_truthy

      cwl = ComponentWhitelist.new({:name => 'HubaBuba', :user_id => 'asgfasga'})
      expect( cwl.save ).to be_truthy

      cwls = ComponentWhitelistService.index user
      expect( cwls ).to_not be_nil
      expect( cwls.first.name ).to eq("OkForMe")
      expect( cwls.count ).to eq(1)
    end

    it 'returns the all whitelists in enterprise env' do
      user  = UserFactory.create_new 1
      admin = UserFactory.create_new 2

      lwl = ComponentWhitelist.new({:name => 'OkForMe', :user_id => admin.id})
      expect( lwl.save ).to be_truthy

      lwl = ComponentWhitelist.new({:name => 'HubaBuba', :user_id => admin.id})
      expect( lwl.save ).to be_truthy

      Settings.instance.instance_variable_set(:@environment, 'enterprise')

      lwls = ComponentWhitelistService.index user
      expect( lwls ).to_not be_nil
      expect( lwls.count ).to eq(2)
      expect( lwls.first.name ).to eq("OkForMe")

      Settings.instance.instance_variable_set(:@environment, 'test')
    end

  end


  describe 'fetch_by' do

    it 'returns the list for the given user' do
      user = UserFactory.create_new 1
      cwl = ComponentWhitelist.new({:name => 'OkForMe', :user_id => user.id})
      cwl.save

      cwl = ComponentWhitelist.new({:name => 'HubaBuba', :user_id => 'asgfasga'})
      cwl.save

      cw = ComponentWhitelistService.fetch_by user, 'OkForMe'
      expect( cw ).to_not be_nil
      expect( cw.name ).to eq('OkForMe')
    end

    it 'returns the list with given name, even if user is not owner of the list (Enterprise env)' do
      user  = UserFactory.create_new 1
      admin = UserFactory.create_new 2

      cwl = ComponentWhitelist.new({:name => 'OkForMe', :user_id => admin.id})
      cwl.save

      cwl = ComponentWhitelist.new({:name => 'HubaBuba', :user_id => admin.id})
      cwl.save

      Settings.instance.instance_variable_set(:@environment, 'enterprise')

      cw = ComponentWhitelistService.fetch_by user, 'OkForMe'
      expect( cw ).to_not be_nil
      expect( cw.name ).to eq("OkForMe")

      Settings.instance.instance_variable_set(:@environment, 'test')
    end

  end


  describe 'create_for' do

    it 'create a list for a user' do
      user = UserFactory.create_new 1
      resp = ComponentWhitelistService.create user, 'SuperList'
      expect( resp ).to be_truthy
      expect( ComponentWhitelist.count ).to eq(1)
      expect( ComponentWhitelist.first.user.ids ).to eq(user.ids)
    end

    it 'returns the list with given name, even if user is not owner of the list (Enterprise env)' do
      user  = UserFactory.create_new 1
      admin = UserFactory.create_new 2
      admin.admin = true
      admin.save

      Settings.instance.instance_variable_set(:@environment, 'enterprise')

      expect( ComponentWhitelistService.create(user, 'SuperList') ).to be_falsy
      expect( ComponentWhitelistService.create(admin, 'SuperList') ).to be_truthy

      Settings.instance.instance_variable_set(:@environment, 'test')
    end

  end


  describe 'add' do

    it 'add new license to list for a user' do
      user = UserFactory.create_new 1

      expect(ComponentWhitelistService.create(user, 'SuperList')).to be_truthy
      expect(ComponentWhitelistService.add(user, 'SuperList', 'MIT')).to be_truthy

      list = ComponentWhitelistService.fetch_by user, 'SuperList'
      expect( list.components.count ).to eq(1)
      expect( list.components.first ).to eq('mit')
    end

    it 'add new license to list for user (Enterprise env)' do
      user  = UserFactory.create_new 1
      admin = UserFactory.create_new 2
      admin.admin = true
      admin.save

      Settings.instance.instance_variable_set(:@environment, 'enterprise')

      expect(ComponentWhitelistService.create(admin, 'SuperList')).to be_truthy
      expect(ComponentWhitelistService.add(user,     'SuperList', 'MIT')).to be_falsy
      expect(ComponentWhitelistService.add(admin,    'SuperList', 'MIT')).to be_truthy

      Settings.instance.instance_variable_set(:@environment, 'test')
    end

  end


  describe 'remove' do

    it 'remove license from list for a user' do
      user = UserFactory.create_new 1

      ComponentWhitelistService.create user, 'SuperList'
      ComponentWhitelistService.add user, 'SuperList', 'mit'
      list = ComponentWhitelistService.fetch_by user, 'SuperList'
      expect( list.components.count ).to eq(1)

      expect( ComponentWhitelistService.remove user, 'SuperList', 'mit' ).to be_truthy
      list = ComponentWhitelistService.fetch_by user, 'SuperList'
      expect( list.components.count ).to eq(0)
    end

    it 'remove license from list for a user (Enterprise env)' do
      user  = UserFactory.create_new 1
      admin = UserFactory.create_new 2
      admin.admin = true
      admin.save

      Settings.instance.instance_variable_set(:@environment, 'enterprise')

      ComponentWhitelistService.create admin, 'SuperList'
      ComponentWhitelistService.add admin, 'SuperList', 'mit'
      expect( ComponentWhitelistService.fetch_by(admin, 'SuperList').components.count ).to eq(1)

      expect( ComponentWhitelistService.remove user, 'SuperList', 'MIT' ).to be_falsy

      list = ComponentWhitelistService.fetch_by admin, 'SuperList'
      expect( list.components.count ).to eq(1)

      expect( ComponentWhitelistService.remove admin, 'SuperList', 'MIT' ).to be_truthy

      list = ComponentWhitelistService.fetch_by admin, 'SuperList'
      expect( list.components.count ).to eq(0)

      Settings.instance.instance_variable_set(:@environment, 'test')
    end

  end


  describe 'enterprise_permission' do

    it 'returns false because user is nil' do
      ComponentWhitelistService.enterprise_permission(nil).should be_falsy
    end
    it 'returns false because user is not admin' do
      user = UserFactory.create_new 1
      user.admin = false
      user.fetch_or_create_permissions.lwl = false
      ComponentWhitelistService.enterprise_permission(user).should be_falsy
    end
    it 'returns true because user is admin' do
      user = UserFactory.create_new 1
      user.admin = true
      user.fetch_or_create_permissions.lwl = false
      ComponentWhitelistService.enterprise_permission(user).should be_truthy
    end
    it 'returns true because user has lwl permission' do
      user = UserFactory.create_new 1
      user.admin = false
      user.fetch_or_create_permissions.lwl = true
      ComponentWhitelistService.enterprise_permission(user).should be_truthy
    end

  end


  describe 'default' do

    it 'sets the default' do
      user = UserFactory.create_new 1
      expect( ComponentWhitelistService.create user, 'SuperList').to be_truthy
      expect( ComponentWhitelistService.create user, 'MyList'   ).to be_truthy
      expect( ComponentWhitelistService.create user, 'YourList' ).to be_truthy

      expect( ComponentWhitelist.count ).to eq(3)
      ComponentWhitelist.all.each do |cwl|
        expect( cwl.default ).to be_falsy
      end

      ComponentWhitelistService.default user, 'MyList'
      cwl = ComponentWhitelist.fetch_by user, 'MyList'
      expect( cwl.default ).to be_truthy

      cwl = ComponentWhitelist.fetch_by user, 'SuperList'
      expect( cwl.default ).to be_falsy

      cwl = ComponentWhitelist.fetch_by user, 'YourList'
      expect( cwl.default ).to be_falsy
    end

  end


  describe 'fetch_default_id' do

    it 'returns nil because there is no default' do
      user = UserFactory.create_new 1
      ComponentWhitelistService.create user, 'SuperList'
      expect( ComponentWhitelistService.fetch_default_id(user) ).to be_nil
    end

    it 'returns the default_id' do
      user = UserFactory.create_new 1
      ComponentWhitelistService.create user, 'SuperList'
      ComponentWhitelistService.create user, 'MyList'

      ComponentWhitelistService.default user, 'MyList'
      cwl = ComponentWhitelist.fetch_by user, 'MyList'

      expect( ComponentWhitelistService.fetch_default_id(user) ).to eq(cwl.ids)
    end

  end


  describe 'update_project' do

    it 'returns false because no project' do
      expect( ComponentWhitelistService.update_project nil, nil, nil ).to be_falsy
    end

    it 'updates the project with the given lwl' do
      user = UserFactory.create_new 1

      project = ProjectFactory.create_new user
      prod_1  = ProductFactory.create_new 1
      dep_1   = ProjectdependencyFactory.create_new project, prod_1, true
      dep_1.version_requested = prod_1.version
      dep_1.save

      project_2 = ProjectFactory.create_new user
      prod_2  = ProductFactory.create_new 2
      dep_2   = ProjectdependencyFactory.create_new project_2, prod_2, true
      dep_2.version_requested = prod_2.version
      dep_2.save
      project_2.parent_id = project.ids
      project_2.save

      ComponentWhitelistService.create user, 'SuperList'
      ComponentWhitelistService.add user, 'SuperList', dep_1.cwl_key
      ComponentWhitelistService.add user, 'SuperList', dep_2.cwl_key

      expect( ComponentWhitelistService.update_project(project, user, 'SuperList') ).to be_truthy
      project = Project.first
      expect( project.licenses_red ).to eq(0)
      expect( project.licenses_red_sum ).to eq(0)
    end

  end

end
