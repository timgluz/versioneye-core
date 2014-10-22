class LicenseWhitelistService < Versioneye::Service

  def self.index user
    env  = Settings.instance.environment
    list = index_enterprise() if env.eql?("enterprise")
    list = index_for( user )  if not env.eql?("enterprise")
    list
  end

  def self.fetch_by user, name
    env  = Settings.instance.environment
    list = fetch_by_enterprise( name )      if env.eql?("enterprise")
    list = fetch_by_user_name( user, name ) if not env.eql?("enterprise")
    list
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

end
