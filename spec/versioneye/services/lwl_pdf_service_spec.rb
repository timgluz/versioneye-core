require 'spec_helper'

describe LwlPdfService do

  describe 'fill_dto' do

    it 'it fills the dto' do
      user = UserFactory.create_new 1
      lwl = LicenseWhitelist.new({:name => 'OkForMe', :user_id => user.id})
      lwl.save.should be_truthy

      prod_1  = ProductFactory.create_new 1
      project = ProjectFactory.create_new user
      dep_1 = ProjectdependencyFactory.create_new project, prod_1, true
      dep_1.save

      project.lwl_pdf_list.should be_nil
      described_class.fill_dto project, false

      project.lwl_pdf_list[:unknown].count.should eq(1)
      project.lwl_pdf_list[:whitelisted].count.should eq(0)
      project.lwl_pdf_list[:violated].count.should eq(0)
    end

    it 'it fills the dto' do
      user = UserFactory.create_new 1
      lwl = LicenseWhitelist.new({:name => 'OkForMe', :user_id => user.id})
      lwl.save.should be_truthy
      LicenseWhitelistService.add user, 'OkForMe', 'MIT'

      prod_1  = ProductFactory.create_new 1
      project = ProjectFactory.create_new user
      project.license_whitelist_id = lwl.id
      project.save

      dep_1 = ProjectdependencyFactory.create_new project, prod_1, true
      dep_1.license_caches = []
      dep_1.license_caches << LicenseCach.new({:name => 'MIT', :on_whitelist => true})
      dep_1.save
      p dep_1.license_caches

      project.lwl_pdf_list.should be_nil
      described_class.fill_dto project, false

      project.lwl_pdf_list[:unknown].count.should eq(0)
      project.lwl_pdf_list[:whitelisted].count.should eq(1)
      project.lwl_pdf_list[:violated].count.should eq(0)
    end

    it 'it fills the dto, only 1 dependency on the list because uniq contstraint!' do
      user = UserFactory.create_new 1
      lwl = LicenseWhitelist.new({:name => 'OkForMe', :user_id => user.id})
      lwl.save.should be_truthy
      LicenseWhitelistService.add user, 'OkForMe', 'MIT'

      prod_1  = ProductFactory.create_new 1
      project_1 = ProjectFactory.create_new user
      project_1.license_whitelist_id = lwl.id
      project_1.save

      dep_1 = ProjectdependencyFactory.create_new project_1, prod_1, true
      dep_1.license_caches = []
      dep_1.license_caches << LicenseCach.new({:name => 'MIT', :on_whitelist => true})
      dep_1.save

      project_2 = ProjectFactory.create_new user
      project_2.license_whitelist_id = lwl.id
      project_2.parent_id = project_1.id
      project_2.save

      dep_2 = ProjectdependencyFactory.create_new project_2, prod_1, true
      dep_2.license_caches = []
      dep_2.license_caches << LicenseCach.new({:name => 'MIT', :on_whitelist => true})
      dep_2.save

      project_1.lwl_pdf_list.should be_nil
      described_class.fill_dto project_1, true

      project_1.lwl_pdf_list[:unknown].count.should eq(0)
      project_1.lwl_pdf_list[:whitelisted].count.should eq(1)
      project_1.lwl_pdf_list[:violated].count.should eq(0)
    end


    it 'it fills the dto, 2 dependency on the list because not unique and not flatten!' do
      user = UserFactory.create_new 1
      lwl = LicenseWhitelist.new({:name => 'OkForMe', :user_id => user.id})
      lwl.save.should be_truthy
      LicenseWhitelistService.add user, 'OkForMe', 'MIT'

      prod_1  = ProductFactory.create_new 1
      project_1 = ProjectFactory.create_new user
      project_1.license_whitelist_id = lwl.id
      project_1.save

      dep_1 = ProjectdependencyFactory.create_new project_1, prod_1, true
      dep_1.license_caches = []
      dep_1.license_caches << LicenseCach.new({:name => 'MIT', :on_whitelist => true})
      dep_1.save

      project_2 = ProjectFactory.create_new user
      project_2.license_whitelist_id = lwl.id
      project_2.parent_id = project_1.id
      project_2.save

      prod_2  = ProductFactory.create_new 2
      dep_2 = ProjectdependencyFactory.create_new project_2, prod_2, true
      dep_2.license_caches = []
      dep_2.license_caches << LicenseCach.new({:name => 'MIT', :on_whitelist => true})
      dep_2.save

      project_1.lwl_pdf_list.should be_nil
      described_class.fill_dto project_1, true

      project_1.lwl_pdf_list[:unknown].count.should eq(0)
      project_1.lwl_pdf_list[:whitelisted].count.should eq(2)
      project_1.lwl_pdf_list[:violated].count.should eq(0)
    end

  end

end
