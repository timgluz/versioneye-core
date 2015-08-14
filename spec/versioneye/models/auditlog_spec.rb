require 'spec_helper'

describe Auditlog do

  describe "create_new" do

    it "creates a new Autditlog" do
      expect( Auditlog.count ).to eq(0)
      user = UserFactory.create_new
      expect( Auditlog.add(user, "LicenseWhitelist", '2', 'Added MIT')).to be_truthy
      expect( Auditlog.count ).to eq(1)
      expect( Auditlog.first.user ).to_not be_nil
    end

  end

end
