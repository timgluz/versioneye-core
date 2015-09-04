class LdapService < Versioneye::Service


  require 'net/ldap'


  def self.auth_by login, password, ldap = Net::LDAP.new
  	Settings.instance.reload_from_db GlobalSetting.new
  	filter = Settings.instance.ldap_filter
  	filter = filter.gsub("LOGIN", login)
    ldap = Net::LDAP.new() if ldap.nil?
    ldap.host = Settings.instance.ldap_host
    ldap.port = Settings.instance.ldap_port
    ldap.bind_as(:base => Settings.instance.ldap_base,
    	         :filter => filter,
    	         :password => password )
  end


end
