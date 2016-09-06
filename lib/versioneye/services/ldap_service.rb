class LdapService < Versioneye::Service


  require 'net/ldap'


  def self.auth_by login, password, ldap = nil
    Settings.instance.reload_from_db GlobalSetting.new

    env = Settings.instance.environment
    auth_method = GlobalSetting.get env, 'ldap_auth'
    auth_method = "simple" if auth_method.to_s.empty?

    username = GlobalSetting.get env, 'ldap_username_pattern'
    username = Settings.instance.ldap_username_pattern if username.to_s.empty?
    username = username.gsub("LOGIN", login)

    filter = GlobalSetting.get env, 'ldap_filter'
    filter = Settings.instance.ldap_filter if filter.to_s.empty?
    filter = filter.gsub("LOGIN", login)

    ldap_base = GlobalSetting.get env, 'ldap_base'
    ldap_base = Settings.instance.ldap_base if ldap_base.to_s.empty?

    ldap_host = GlobalSetting.get(env, 'ldap_host')
    ldap_host = Settings.instance.ldap_host if ldap_host.to_s.empty?

    ldap_port = GlobalSetting.get(env, 'ldap_port')
    ldap_port = Settings.instance.ldap_port if ldap_port.to_s.empty?

    if ldap.nil?
      ldap_args = {:host => ldap_host,
                   :port => ldap_port,
                   :base => ldap_base,
                   :auth => {:username => username,
                             :password => password,
                             :method => auth_method.to_sym } }
      ldap = Net::LDAP.new( ldap_args )
    end

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
    log.error e.backtrace.join("\n")
    e.message
  end


end
