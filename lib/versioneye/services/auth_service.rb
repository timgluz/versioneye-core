class AuthService < Versioneye::Service


  def self.auth login, password, ldap = nil
    user = User.authenticate(login, password)
    return user if user

    if !defined?(Settings.instance.ldap_active) ||
       Settings.instance.ldap_active.nil? ||
       !Settings.instance.ldap_active.to_s.eql?('true')
      return nil
    end

    entity = LdapService.auth_by login, password, ldap
    return nil if entity.nil? || entity.to_s.empty?

    return user_for entity
  end


  private


    def self.user_for entity
      first_entity = entity.first

      username = first_entity[Settings.instance.ldap_username].first        if first_entity[Settings.instance.ldap_username]
      username = first_entity[Settings.instance.ldap_username.to_sym].first if first_entity[Settings.instance.ldap_username.to_sym]

      email    = first_entity[Settings.instance.ldap_email].first        if first_entity[Settings.instance.ldap_email]
      email    = first_entity[Settings.instance.ldap_email.to_sym].first if first_entity[Settings.instance.ldap_email.to_sym]

      user = User.find_by_username username
      return user if user

      user = User.find_by_email email
      return user if user

      user = User.new({:fullname => username, :email => email,
        :terms => true, :datenerhebung => true})
      user.create_username
      user.save
      user
    rescue => e
      log.error e.message
      log.error e.backtrace.join("\n")
      nil
    end


end
