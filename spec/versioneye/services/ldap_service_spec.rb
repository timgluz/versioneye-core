require 'spec_helper'

describe LdapService do

  describe 'auth_by' do

    it 'returns the ldap entity' do
      ldap = LdapMock.new
      ldap.username = 'rreiz'
      ldap.password = 'reiz'
      entity = LdapService.auth_by 'rreiz', 'reiz', ldap
      expect( entity ).to_not be_nil
    end

  end

end
