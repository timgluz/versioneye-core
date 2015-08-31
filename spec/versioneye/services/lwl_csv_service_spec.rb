require 'spec_helper'

describe LwlCsvService do


  describe 'process' do
    it 'proccesses the project correctly' do
      user = UserFactory.create_new 1

      lwl = LicenseWhitelist.new({:name => 'OkForMe', :user_id => user.id})
      lwl.add_license_element "MIT"
      expect( lwl.save ).to be_truthy

      cwl = ComponentWhitelist.new({:name => 'CWL', :user_id => user.id})
      cwl.add 'junit:junit'
      expect( cwl.save ).to be_truthy

      prod_1  = ProductFactory.create_new 1
      project = ProjectFactory.create_new user
      dep_1   = ProjectdependencyFactory.create_new project, prod_1, true
      dep_1.save
      project.license_whitelist_id = lwl.ids
      project.component_whitelist_id = cwl.ids
      expect( project.save ).to be_truthy

      csv_string = LwlCsvService.process project
      expect( csv_string ).to_not be_nil
    end
  end


end
