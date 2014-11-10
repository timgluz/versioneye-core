require 'spec_helper'

describe Auditlog do

  describe "create_new" do

    it "creates a new Autditlog" do
      Auditlog.count.should eq(0)
      user = UserFactory.create_new
      Auditlog.add(user, "LicenseWhitelist", '2', 'Added MIT').should be_truthy
      Auditlog.count.should eq(1)
    end

  end

end
