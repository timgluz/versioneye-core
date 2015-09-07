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
  rescue => e
    log.error e.message
    e.message
  end


  def self.search_code login, ldap = Net::LDAP.new
    filter = Settings.instance.ldap_filter
    filter = filter.gsub("LOGIN", login)
    ldap = Net::LDAP.new() if ldap.nil?
    ldap.host = Settings.instance.ldap_host
    ldap.port = Settings.instance.ldap_port
    ldap.search(:base => Settings.instance.ldap_base,
              :filter => filter)
    result = ldap.get_operation_result
    log.info "LDAP Code: #{result.code}. Message: #{result.message}. Error Message: #{result.error_message}"
    return "" if result.message.eql?('Success') && result.error_message.to_s.empty?
    "Code: #{result.code}. Message: #{result.message} #{result.error_message}"
  rescue => e
    log.error e.message
    e.message
  end


end
