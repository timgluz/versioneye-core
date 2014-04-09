require 'spec_helper'

describe AdminService do

  describe "create_default_admin" do

    it "creates the default admin" do
      AdminService.create_default_admin.should be_true
      AdminService.create_default_admin.should be_false
      admin = User.find_by_username 'admin'
      admin.should_not be_nil
      admin.verification.should be_nil
      admin[:terms].should be_true
      admin[:datenerhebung].should be_true
      admin[:admin].should be_true
    end

  end

end
