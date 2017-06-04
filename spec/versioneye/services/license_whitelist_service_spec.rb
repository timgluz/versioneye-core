require 'spec_helper'

describe LicenseWhitelistService do

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
      lwl = LicenseWhitelist.new({ :name => 'OkForMe', :organisation_id => @orga.id })
      lwl.save.should be_truthy
      lwls = LicenseWhitelistService.index @orga
      lwls.should_not be_nil
      lwls.first.name.should eq("default_lwl")
      lwls.last.name.should eq("OkForMe")
      expect( lwls.count ).to eq(2)
    end

  end

  describe 'fetch_by' do

    it 'returns the list for the given user' do
      lwl = LicenseWhitelist.new({:name => 'OkForMe', :organisation_id => @orga.id})
      lwl.save.should be_truthy
      lw = LicenseWhitelistService.fetch_by @orga, 'OkForMe'
      lw.should_not be_nil
      lw.name.should eq('OkForMe')
    end

  end

  describe 'create_for' do

    it 'create a list for a user' do
      resp = LicenseWhitelistService.create @orga, 'SuperList'
      expect( resp ).to be_truthy
    end

  end

  describe 'add' do

    it 'add new license to list for a user' do
      resp = LicenseWhitelistService.create @orga, 'SuperList'
      expect( resp ).to be_truthy
      resp = LicenseWhitelistService.add @orga, 'SuperList', 'MIT'
      expect( resp ).to be_truthy
      @orga.reload
      expect( @orga.license_whitelists.count ).to eq(2)
      list = LicenseWhitelistService.fetch_by @orga, 'SuperList'
      list.license_elements.count.should eq(1)
      list.license_elements.first.name.should eq('MIT')
    end

  end

  describe 'default' do

    it 'sets the default' do
      resp = LicenseWhitelistService.create @orga, 'SuperList'
      expect( resp ).to be_truthy
      resp = LicenseWhitelistService.create @orga, 'MyList'
      expect( resp ).to be_truthy
      resp = LicenseWhitelistService.create @orga, 'YourList'
      expect( resp ).to be_truthy
      @orga.reload
      expect( @orga.license_whitelists.count ).to eq(4)

      LicenseWhitelist.count.should eq(4)
      LicenseWhitelist.all.each do |lwl|
        next if lwl.name.eql?('default_lwl')
        lwl.default.should be_falsy
      end

      LicenseWhitelistService.default @orga, 'MyList'
      lwl = LicenseWhitelist.fetch_by @orga, 'MyList'
      lwl.default.should be_truthy
      lwl = LicenseWhitelist.fetch_by @orga, 'SuperList'
      lwl.default.should be_falsy
      lwl = LicenseWhitelist.fetch_by @orga, 'YourList'
      lwl.default.should be_falsy
    end

  end

  describe 'remove' do

    it 'remove license from list for a user' do
      resp = LicenseWhitelistService.create @orga, 'SuperList'
      resp = LicenseWhitelistService.add @orga, 'SuperList', 'MIT'
      list = LicenseWhitelistService.fetch_by @orga, 'SuperList'
      list.license_elements.count.should eq(1)
      resp = LicenseWhitelistService.remove @orga, 'SuperList', 'MIT'
      resp.should be_truthy
      list = LicenseWhitelistService.fetch_by @orga, 'SuperList'
      list.license_elements.count.should eq(0)
    end

  end


  describe 'update_project' do

    it 'returns false because no project' do
      expect( LicenseWhitelistService.update_project nil, nil, nil ).to be_falsy
    end

    it 'updates the project with the given lwl' do
      LicenseWhitelistService.create @orga, 'SuperList'
      LicenseWhitelistService.add @orga, 'SuperList', 'MIT'

      user = UserFactory.create_new
      project = ProjectFactory.create_new user
      project.organisation_id = @orga.ids
      expect( project.save ).to be_truthy
      prod_1  = ProductFactory.create_new 1
      dep_1   = ProjectdependencyFactory.create_new project, prod_1, true
      dep_1.version_requested = prod_1.version
      dep_1.save
      LicenseFactory.create_new prod_1, 'GPL'

      project_2 = ProjectFactory.create_new user
      project_2.organisation_id = @orga.ids
      project_2.save
      prod_2  = ProductFactory.create_new 2
      dep_2   = ProjectdependencyFactory.create_new project_2, prod_2, true
      dep_2.version_requested = prod_2.version
      dep_2.save
      LicenseFactory.create_new prod_2, 'GPL'
      project_2.parent_id = project.ids
      project_2.save

      expect( LicenseWhitelistService.update_project(project, @orga, 'SuperList') ).to be_truthy
      project = Project.first
      expect( project.licenses_red ).to eq(1)
      expect( project.licenses_red_sum ).to eq(2)
    end

  end

end
