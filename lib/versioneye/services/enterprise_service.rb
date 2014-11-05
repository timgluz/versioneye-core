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

end
