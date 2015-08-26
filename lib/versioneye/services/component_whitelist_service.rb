class ComponentWhitelistService < Versioneye::Service

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

  def self.add user, list_name, cwl_key
    env = Settings.instance.environment
    success = add_for_enterprise( user, list_name, cwl_key ) if env.eql?(A_ENV_ENTERPRISE)
    success = add_key( user, list_name, cwl_key )            if not env.eql?(A_ENV_ENTERPRISE)
    success
  end

  def self.remove user, list_name, cwl_key
    env = Settings.instance.environment
    success = remove_for_enterprise( user, list_name, cwl_key.downcase ) if env.eql?(A_ENV_ENTERPRISE)
    success = remove_key( user, list_name, cwl_key.downcase )            if not env.eql?(A_ENV_ENTERPRISE)
    success
  end

  def self.default user, list_name
    list = index( user )
    list.each do |cwl|
      if cwl.name.eql?( list_name )
        cwl.default = true
      else
        cwl.default = false
      end
      cwl.save
    end
  end


  def self.fetch_default_id user
    list = index( user )
    list.each do |cwl|
      return cwl.id.to_s if cwl.default == true
    end
    nil
  end


  def self.update_project project, user, cwl_name
    return false if project.nil?

    cwl = fetch_by user, cwl_name
    cwl_id = nil
    cwl_id = cwl.ids if cwl

    project.component_whitelist_id = cwl_id
    ProjectService.update_license_numbers! project

    project.children.each do |child|
      child.license_whitelist_id = cwl_id
      ProjectService.update_license_numbers! child
    end
    ProjectService.update_sums project
    true
  rescue => e
    log.error e.message
    log.error e.backtrace.join "\n"
    false
  end


  # Returns true if user has permission to edit lwl for enterprise
  def self.enterprise_permission user
    return false if user.nil?
    return true  if user.admin == true
    return true  if user.fetch_or_create_permissions.lwl == true
    return false
  end

  private

    def self.index_enterprise
      ComponentWhitelist.all
    end

    def self.index_for user
      ComponentWhitelist.by_user user
    end

    def self.fetch_by_enterprise name
      ComponentWhitelist.by_name( name ).first
    end

    def self.fetch_by_user_name user, name
      ComponentWhitelist.fetch_by user, name
    end

    def self.create_for user, name
      cwl = ComponentWhitelist.new( {:name => name} )
      cwl.user = user
      cwl.save
    end

    def self.create_for_enterprise user, name
      return false if enterprise_permission(user) == false
      create_for user, name
    end

    def self.add_key user, list_name, cwl_key
      cwl = ComponentWhitelist.fetch_by user, list_name
      cwl.add cwl_key
      cwl.save
    end

    def self.add_for_enterprise user, list_name, cwl_key
      return false if enterprise_permission(user) == false
      cwl = ComponentWhitelist.by_name( list_name ).first
      cwl.add cwl_key
      cwl.save
    end

    def self.remove_key user, list_name, cwl_key
      cwl = ComponentWhitelist.fetch_by user, list_name
      cwl.remove cwl_key
      cwl.save
    end

    def self.remove_for_enterprise user, list_name, cwl_key
      return false if enterprise_permission(user) == false
      cwl = ComponentWhitelist.by_name( list_name ).first
      cwl.remove cwl_key
      cwl.save
    end

end
