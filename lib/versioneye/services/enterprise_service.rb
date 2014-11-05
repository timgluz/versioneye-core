class EnterpriseService < Versioneye::Service

  def self.activated?
    env = Settings.instance.environment
    return true if !env.eql?('enterprise')

    api_key    = GlobalSetting.get env, 'API_KEY'
    e_projects = GlobalSetting.get env, 'E_PROJECTS'
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
    GlobalSetting.set env, 'E_PROJECTS', response["enterprise_projects"]
    GlobalSetting.set env, 'API_KEY', api_key
    GlobalSetting.set env, 'ACTIVATION_DATE', Time.now.strftime("%Y-%m-%d")

    GlobalSetting.get( env, 'API_KEY' ).eql?( api_key )
  rescue => e
    log.error e.message
    log.error e.backtrace.join "\n"
    false
  end

end
