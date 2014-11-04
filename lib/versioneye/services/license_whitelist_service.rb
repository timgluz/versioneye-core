class LicenseWhitelistService < Versioneye::Service

  A_ENV_ENTERPRISE = "enterprise"

  def self.index user
    env  = Settings.instance.environment
    list = index_enterprise() if env.eql?( A_ENV_ENTERPRISE )
    list = index_for( user )  if not env.eql?( A_ENV_ENTERPRISE )
    list
  end

  def self.fetch_by user, name
    env  = Settings.instance.environment
    list = fetch_by_enterprise( name )      if env.eql?(A_ENV_ENTERPRISE)
    list = fetch_by_user_name( user, name ) if not env.eql?(A_ENV_ENTERPRISE)
    list
  end

  def self.create user, name
    env = Settings.instance.environment
    success = create_for_enterprise( user, name ) if env.eql?(A_ENV_ENTERPRISE)
    success = create_for( user, name )            if not env.eql?(A_ENV_ENTERPRISE)
    success
  end

  def self.add user, list_name, license_name
    env = Settings.instance.environment
    success = add_license_for_enterprise( user, list_name, license_name ) if env.eql?(A_ENV_ENTERPRISE)
    success = add_license( user, list_name, license_name )                if not env.eql?(A_ENV_ENTERPRISE)
    success
  end

  def self.remove user, list_name, license_name
    env = Settings.instance.environment
    success = remove_license_for_enterprise( user, list_name, license_name ) if env.eql?(A_ENV_ENTERPRISE)
    success = remove_license( user, list_name, license_name )                if not env.eql?(A_ENV_ENTERPRISE)
    success
  end

  private

    def self.index_enterprise
      LicenseWhitelist.all
    end

    def self.index_for user
      LicenseWhitelist.by_user user
    end

    def self.fetch_by_enterprise name
      LicenseWhitelist.by_name( name ).first
    end

    def self.fetch_by_user_name user, name
      LicenseWhitelist.fetch_by user, name
    end

    def self.create_for user, name
      whitelist = LicenseWhitelist.new( {:name => name} )
      whitelist.user = user
      whitelist.save
    end

    def self.create_for_enterprise user, name
      return false if user.nil? || user.admin != true
      create_for user, name
    end

    def self.add_license user, list_name, license_name
      license_whitelist = LicenseWhitelist.fetch_by user, list_name
      license_whitelist.add_license_element license_name
      license_whitelist.save
    end

    def self.add_license_for_enterprise user, list_name, license_name
      return false if user.nil? || user.admin != true
      license_whitelist = LicenseWhitelist.by_name( list_name ).first
      license_whitelist.add_license_element license_name
      license_whitelist.save
    end

    def self.remove_license user, list_name, license_name
      license_whitelist = LicenseWhitelist.fetch_by user, list_name
      license_whitelist.remove_license_element license_name
      license_whitelist.save
    end

    def self.remove_license_for_enterprise user, list_name, license_name
      return false if user.nil? || user.admin != true
      license_whitelist = LicenseWhitelist.by_name( list_name ).first
      license_whitelist.remove_license_element license_name
      license_whitelist.save
    end

end
