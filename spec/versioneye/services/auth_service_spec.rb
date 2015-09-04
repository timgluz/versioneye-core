require 'spec_helper'

describe AuthService do

  describe "auth" do

    it "returns nil" do
      expect( AuthService.auth('rezi', 'rozi') ).to be_nil
    end

    it "returns user from DB" do
      user = UserFactory.create_new 1
      expect( AuthService.auth( user.username, '12345') ).to_not be_nil
    end

    it "returns user from LDAP" do
      ldap = LdapMock.new
      ldap.username = 'rreiz'
      ldap.password = 'reiz'
      ldap.email = 'reiz@versioneye.com'
      Settings.instance.ldap_active = true

      expect( User.count ).to eq(0)
      expect( AuthService.auth( 'rreiz', 'reiz', ldap) ).to_not be_nil
      expect( User.count ).to eq(1)

      expect( AuthService.auth( 'rreiz', 'reiz', ldap) ).to_not be_nil
      expect( User.count ).to eq(1)
    end


  end


end
