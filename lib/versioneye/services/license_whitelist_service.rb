class LicenseWhitelistService < Versioneye::Service

  A_ENV_ENTERPRISE = "enterprise"

  def self.index orga
    LicenseWhitelist.by_orga orga
  end

  def self.fetch_by orga, name
    LicenseWhitelist.fetch_by orga, name
  end

  def self.create orga, name
    whitelist = LicenseWhitelist.new( {:name => name} )
    whitelist.organisation = orga
    orga.license_whitelists.push whitelist
    orga.save
    if whitelist.save
      return whitelist
    end
    nil
  end

  def self.add orga, list_name, license_name
    license_whitelist = LicenseWhitelist.fetch_by orga, list_name
    license_whitelist.add_license_element license_name
    license_whitelist.save
  end

  def self.remove orga, list_name, license_name
    license_whitelist = LicenseWhitelist.fetch_by orga, list_name
    license_whitelist.remove_license_element license_name
    license_whitelist.save
  end

  def self.default orga, list_name
    response = false
    list = index( orga )
    list.each do |lwl|
      if lwl.name.eql?( list_name )
        lwl.default = true
        response = true
      else
        lwl.default = false
      end
      lwl.save
    end
    response
  end


  def self.fetch_default_id orga
    list = index( orga )
    list.each do |lwl|
      return lwl.id.to_s if lwl.default == true
    end
    nil
  end


  def self.update_project project, orga, lwl_name
    return false if project.nil?

    lwl = fetch_by orga, lwl_name
    lwl_id = nil
    lwl_id = lwl.id.to_s if lwl

    project.license_whitelist_id = lwl_id
    ProjectService.update_license_numbers! project

    project.children.each do |child|
      child.license_whitelist_id = lwl_id
      ProjectService.update_license_numbers! child
    end
    ProjectService.update_sums project
    true
  rescue => e
    log.error e.message
    log.error e.backtrace.join "\n"
    false
  end


end
