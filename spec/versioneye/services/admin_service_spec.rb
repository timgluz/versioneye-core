require 'spec_helper'

describe AdminService do

  describe "create_default_admin" do

    it "creates the default admin" do
      AdminService.create_default_admin.should be_truthy
      AdminService.create_default_admin.should be_falsey
      admin = User.find_by_username 'admin'
      admin.should_not be_nil
      admin.verification.should be_nil
      admin[:terms].should be_truthy
      admin[:datenerhebung].should be_truthy
      admin[:admin].should be_truthy
    end

  end

end
