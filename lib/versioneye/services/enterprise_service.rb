class EnterpriseService < Versioneye::Service

  def self.activated?
    env = Settings.instance.environment
    return true if !env.eql?('enterprise')

    api_key    = GlobalSetting.get env, 'API-KEY'
    e_projects = GlobalSetting.get env, 'E-PROJECTS'
    return false if api_key.to_s.empty?
    return false if e_projects.to_s.empty?
    return false if e_projects.to_i <= 0
    return true
  end

  def self.activate! api_key
    response = MeClient.show api_key
    return false if response.to_s.empty?
    return false if !response["error"].to_s.empty?

    env = Settings.instance.environment
    GlobalSetting.set env, 'E-PROJECTS', response["enterprise_projects"]
    GlobalSetting.set env, 'API-KEY', api_key

    GlobalSetting.get( env, 'API-KEY' ).eql?( api_key )
  end

end
