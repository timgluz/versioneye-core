class LdapService < Versioneye::Service


  require 'net/ldap'


  def self.auth_by login, password, ldap = Net::LDAP.new
    Settings.instance.reload_from_db GlobalSetting.new

    env = Settings.instance.environment
    auth_method = GlobalSetting.get env, 'ldap_auth'
    auth_method = "simple" if auth_method.to_s.empty?

    username = GlobalSetting.get env, 'ldap_username_pattern'
    username = username.gsub("LOGIN", login)

    filter = GlobalSetting.get env, 'ldap_filter'
    filter = filter.gsub("LOGIN", login)

    ldap_base = GlobalSetting.get env, 'ldap_base'

    ldap_args = {:host => GlobalSetting.get(env, 'ldap_host')
                 :port => GlobalSetting.get(env, 'ldap_port')
                 :base => ldap_base,
                 :auth => {:username => username,
                           :password => password,
                           :method => auth_method.to_sym } }

    ldap = Net::LDAP.new( ldap_args ) if ldap.nil?

    encryption = Settings.instance.ldap_encryption.to_s
    if !encryption.empty? && !encryption.strip.downcase.eql?('none')
      ldap.encryption( :method => encryption.to_sym )
    end

    if ldap.bind == true
      return ldap.search(:base => ldap_base, :filter => filter)
    end

    result = ldap.get_operation_result
    "Code: #{result.code}. Message: #{result.message} #{result.error_message}"
  rescue => e
    log.error e.message
    e.message
  end


end
