require 'spec_helper'

describe ComponentWhitelistService do

  before(:each) do
    Plan.create_defaults
    @user = User.new({:fullname => 'Hans Tanz', :username => 'hanstanz',
      :email => 'hans@tanz.de', :password => 'password', :salt => 'salt',
      :terms => true, :datenerhebung => true})
    @user.save
    @orga = OrganisationService.create_new_for @user
    expect( @orga.save ).to be_truthy
  end

  describe 'index' do

    it 'returns the list for the given orga' do
      cwl = ComponentWhitelist.new({:name => 'OkForMe', :organisation_id => @orga.id})
      expect( cwl.save ).to be_truthy

      user = UserFactory.create_new 981
      orga = OrganisationService.create_new_for user
      expect( orga.save ).to be_truthy
      cwl = ComponentWhitelist.new({:name => 'HubaBuba', :organisation_id => orga.ids})
      expect( cwl.save ).to be_truthy

      cwls = ComponentWhitelistService.index @orga
      expect( cwls ).to_not be_nil
      expect( cwls.first.name ).to eq("OkForMe")
      expect( cwls.count ).to eq(1)
    end

  end


  describe 'fetch_by' do

    it 'returns the list for the given orga' do
      cwl = ComponentWhitelist.new({:name => 'OkForMe', :organisation_id => @orga.id})
      cwl.save

      user = UserFactory.create_new 982
      orga = OrganisationService.create_new_for user
      cwl = ComponentWhitelist.new({:name => 'HubaBuba', :organisation_id => orga.ids})
      cwl.save

      cw = ComponentWhitelistService.fetch_by @orga, 'OkForMe'
      expect( cw ).to_not be_nil
      expect( cw.name ).to eq('OkForMe')
    end

  end


  describe 'create_for' do

    it 'create a list for a user' do
      resp = ComponentWhitelistService.create @orga, 'SuperList'
      expect( resp ).to be_truthy
      expect( ComponentWhitelist.count ).to eq(1)
      expect( ComponentWhitelist.first.organisation ).to_not be_nil
      expect( ComponentWhitelist.first.organisation.ids ).to eq(@orga.ids)
    end

  end


  describe 'add' do

    it 'add new license to list for a user' do
      expect(ComponentWhitelistService.create(@orga, 'SuperList')).to be_truthy
      expect(ComponentWhitelistService.add(@orga, 'SuperList', 'MIT')).to be_truthy

      list = ComponentWhitelistService.fetch_by @orga, 'SuperList'
      expect( list.components.count ).to eq(1)
      expect( list.components.first ).to eq('mit')
    end

  end


  describe 'remove' do

    it 'remove license from list for a orga' do
      ComponentWhitelistService.create @orga, 'SuperList'
      ComponentWhitelistService.add @orga, 'SuperList', 'mit'
      list = ComponentWhitelistService.fetch_by @orga, 'SuperList'
      expect( list.components.count ).to eq(1)

      expect( ComponentWhitelistService.remove @orga, 'SuperList', 'mit' ).to be_truthy
      list = ComponentWhitelistService.fetch_by @orga, 'SuperList'
      expect( list.components.count ).to eq(0)
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
      expect( ComponentWhitelistService.create @orga, 'SuperList').to be_truthy
      expect( ComponentWhitelistService.create @orga, 'MyList'   ).to be_truthy
      expect( ComponentWhitelistService.create @orga, 'YourList' ).to be_truthy

      expect( ComponentWhitelist.count ).to eq(3)
      ComponentWhitelist.all.each do |cwl|
        expect( cwl.default ).to be_falsy
      end

      ComponentWhitelistService.default @orga, 'MyList'
      cwl = ComponentWhitelist.fetch_by @orga, 'MyList'
      expect( cwl.default ).to be_truthy

      cwl = ComponentWhitelist.fetch_by @orga, 'SuperList'
      expect( cwl.default ).to be_falsy

      cwl = ComponentWhitelist.fetch_by @orga, 'YourList'
      expect( cwl.default ).to be_falsy
    end

  end


  describe 'fetch_default_id' do

    it 'returns nil because there is no default' do
      ComponentWhitelistService.create @orga, 'SuperList'
      expect( ComponentWhitelistService.fetch_default_id(@orga) ).to be_nil
    end

    it 'returns the default_id' do
      ComponentWhitelistService.create @orga, 'SuperList'
      ComponentWhitelistService.create @orga, 'MyList'

      ComponentWhitelistService.default @orga, 'MyList'
      cwl = ComponentWhitelist.fetch_by @orga, 'MyList'

      expect( ComponentWhitelistService.fetch_default_id(@orga) ).to eq(cwl.ids)
    end

  end


  describe 'update_project' do

    it 'returns false because no project' do
      expect( ComponentWhitelistService.update_project nil, nil, nil ).to be_falsy
    end

    it 'updates the project with the given lwl' do
      project = ProjectFactory.create_new @user
      prod_1  = ProductFactory.create_new 1
      dep_1   = ProjectdependencyFactory.create_new project, prod_1, true
      dep_1.version_requested = prod_1.version
      dep_1.save

      project_2 = ProjectFactory.create_new @user
      prod_2  = ProductFactory.create_new 2
      dep_2   = ProjectdependencyFactory.create_new project_2, prod_2, true
      dep_2.version_requested = prod_2.version
      dep_2.save
      project_2.parent_id = project.ids
      project_2.save

      ComponentWhitelistService.create @orga, 'SuperList'
      ComponentWhitelistService.add @orga, 'SuperList', dep_1.cwl_key
      ComponentWhitelistService.add @orga, 'SuperList', dep_2.cwl_key

      expect( ComponentWhitelistService.update_project(project, @orga, 'SuperList') ).to be_truthy
      project = Project.first
      expect( project.licenses_red ).to eq(0)
      expect( project.licenses_red_sum ).to eq(0)
    end

  end

end
