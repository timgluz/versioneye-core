class LdapService < Versioneye::Service


  require 'net/ldap'


  def self.auth_by login, password, ldap = Net::LDAP.new
    Settings.instance.reload_from_db GlobalSetting.new

    auth_method = Settings.instance.ldap_auth.to_s
    auth_method = "simple" if auth_method.to_s.empty?

    username = Settings.instance.ldap_username_pattern
    username = username.gsub("LOGIN", login)

    filter = Settings.instance.ldap_filter
    filter = filter.gsub("LOGIN", login)

    ldap_args = {:host => Settings.instance.ldap_host,
                 :port => Settings.instance.ldap_port,
                 :base => Settings.instance.ldap_base,
                 :auth => {:username => username,
                           :password => password,
                           :method => auth_method.to_sym } }

    ldap = Net::LDAP.new( ldap_args )

    encryption = Settings.instance.ldap_encryption.to_s
    if !encryption.empty? && !encryption.strip.downcase.eql?('none')
      ldap.encryption( :method => encryption.to_sym )
    end

    if ldap.bind == true
      return ldap.search(:base => Settings.instance.ldap_base, :filter => filter)
    end

    result = ldap.get_operation_result
    "Code: #{result.code}. Message: #{result.message} #{result.error_message}"
  rescue => e
    log.error e.message
    e.message
  end


end
