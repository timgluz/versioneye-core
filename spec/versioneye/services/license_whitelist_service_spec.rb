require 'spec_helper'

describe LicenseWhitelistService do

  describe 'index' do

    it 'returns the list for the given orga' do
      orga = Organisation.new :name => "orga"
      lwl = LicenseWhitelist.new({ :name => 'OkForMe', :organisation_id => orga.id })
      lwl.save.should be_truthy
      lwl = LicenseWhitelist.new({:name => 'HubaBuba', :organisation_id => 'asgfasga'})
      lwl.save.should be_truthy
      lwls = LicenseWhitelistService.index orga
      lwls.should_not be_nil
      lwls.first.name.should eq("OkForMe")
      lwls.count.should == 1
    end

  end

  describe 'fetch_by' do

    it 'returns the list for the given user' do
      orga = Organisation.new :name => "orga"
      lwl = LicenseWhitelist.new({:name => 'OkForMe', :organisation_id => orga.id})
      lwl.save.should be_truthy
      lwl = LicenseWhitelist.new({:name => 'HubaBuba', :user_id => 'asgfasga'})
      lwl.save.should be_truthy
      lw = LicenseWhitelistService.fetch_by orga, 'OkForMe'
      lw.should_not be_nil
      lw.name.should eq('OkForMe')
    end

  end

  describe 'create_for' do

    it 'create a list for a user' do
      orga = Organisation.new :name => "orga"
      resp = LicenseWhitelistService.create orga, 'SuperList'
      resp.should be_truthy
    end

  end

  describe 'add' do

    it 'add new license to list for a user' do
      orga = Organisation.new :name => "orga"
      resp = LicenseWhitelistService.create orga, 'SuperList'
      resp.should be_truthy
      resp = LicenseWhitelistService.add orga, 'SuperList', 'MIT'
      resp.should be_truthy
      list = LicenseWhitelistService.fetch_by orga, 'SuperList'
      list.license_elements.count.should eq(1)
      list.license_elements.first.name.should eq('MIT')
    end

  end

  describe 'default' do

    it 'sets the default' do
      orga = Organisation.new :name => "orga"
      resp = LicenseWhitelistService.create orga, 'SuperList'
      resp.should be_truthy
      resp = LicenseWhitelistService.create orga, 'MyList'
      resp.should be_truthy
      resp = LicenseWhitelistService.create orga, 'YourList'
      resp.should be_truthy

      LicenseWhitelist.count.should eq(3)
      LicenseWhitelist.all.each do |lwl|
        lwl.default.should be_falsy
      end

      LicenseWhitelistService.default orga, 'MyList'
      lwl = LicenseWhitelist.fetch_by orga, 'MyList'
      lwl.default.should be_truthy
      lwl = LicenseWhitelist.fetch_by orga, 'SuperList'
      lwl.default.should be_falsy
      lwl = LicenseWhitelist.fetch_by orga, 'YourList'
      lwl.default.should be_falsy
    end

  end

  describe 'fetch_default_id' do

    it 'returns nil because there is no default' do
      orga = Organisation.new :name => "orga"
      resp = LicenseWhitelistService.create orga, 'SuperList'
      resp.should be_truthy

      LicenseWhitelist.count.should eq(1)
      LicenseWhitelistService.fetch_default_id(orga).should be_nil
    end

    it 'returns the default_id' do
      orga = Organisation.new :name => "orga"
      resp = LicenseWhitelistService.create orga, 'SuperList'
      resp.should be_truthy
      resp = LicenseWhitelistService.create orga, 'MyList'
      resp.should be_truthy

      LicenseWhitelistService.default orga, 'MyList'
      lwl = LicenseWhitelist.fetch_by orga, 'MyList'

      LicenseWhitelistService.fetch_default_id(orga).should eq(lwl.id.to_s)
    end

  end

  describe 'remove' do

    it 'remove license from list for a user' do
      orga = Organisation.new :name => "orga"

      resp = LicenseWhitelistService.create orga, 'SuperList'
      resp = LicenseWhitelistService.add orga, 'SuperList', 'MIT'
      list = LicenseWhitelistService.fetch_by orga, 'SuperList'
      list.license_elements.count.should eq(1)
      resp = LicenseWhitelistService.remove orga, 'SuperList', 'MIT'
      resp.should be_truthy
      list = LicenseWhitelistService.fetch_by orga, 'SuperList'
      list.license_elements.count.should eq(0)
    end

  end


  describe 'update_project' do

    it 'returns false because no project' do
      expect( LicenseWhitelistService.update_project nil, nil, nil ).to be_falsy
    end

    it 'updates the project with the given lwl' do
      orga = Organisation.new :name => "orga"

      LicenseWhitelistService.create orga, 'SuperList'
      LicenseWhitelistService.add orga, 'SuperList', 'MIT'

      user = UserFactory.create_new
      project = ProjectFactory.create_new user
      project.organisation_id = orga.ids
      expect( project.save ).to be_truthy
      prod_1  = ProductFactory.create_new 1
      dep_1   = ProjectdependencyFactory.create_new project, prod_1, true
      dep_1.version_requested = prod_1.version
      dep_1.save
      LicenseFactory.create_new prod_1, 'GPL'

      project_2 = ProjectFactory.create_new user
      project_2.organisation_id = orga.ids
      project_2.save
      prod_2  = ProductFactory.create_new 2
      dep_2   = ProjectdependencyFactory.create_new project_2, prod_2, true
      dep_2.version_requested = prod_2.version
      dep_2.save
      LicenseFactory.create_new prod_2, 'GPL'
      project_2.parent_id = project.ids
      project_2.save

      expect( LicenseWhitelistService.update_project(project, orga, 'SuperList') ).to be_truthy
      project = Project.first
      expect( project.licenses_red ).to eq(1)
      expect( project.licenses_red_sum ).to eq(2)
    end

  end

end
