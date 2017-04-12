class ComponentWhitelistService < Versioneye::Service


  def self.index organisation
    ComponentWhitelist.by_orga organisation
  end

  def self.fetch_by organisation, name
    ComponentWhitelist.fetch_by organisation, name
  end

  def self.create organisation, name
    cwl = ComponentWhitelist.new( {:name => name} )
    cwl.organisation = organisation
    cwl.save
  end

  def self.add organisation, list_name, cwl_key
    return false if cwl_key.to_s.empty?

    cwl = ComponentWhitelist.fetch_by organisation, list_name
    cwl.add cwl_key
    cwl.save
  rescue => e
    log.error e.message
    log.error e.backtrace.join "\n"
    false
  end

  def self.remove organisation, list_name, cwl_key
    cwl = ComponentWhitelist.fetch_by organisation, list_name
    cwl.remove cwl_key
    cwl.save
  rescue => e
    log.error e.message
    log.error e.backtrace.join "\n"
    false
  end

  def self.default organisation, list_name
    list = index( organisation )
    list.each do |cwl|
      if cwl.name.eql?( list_name )
        cwl.default = true
      else
        cwl.default = false
      end
      cwl.save
    end
  end


  def self.fetch_default_id organisation
    list = index( organisation )
    list.each do |cwl|
      return cwl.id.to_s if cwl.default == true
    end
    nil
  end


  def self.update_project project, organisation, cwl_name
    return false if project.nil?

    cwl = fetch_by organisation, cwl_name
    cwl_id = nil
    cwl_id = cwl.ids if cwl

    project.component_whitelist_id = cwl_id
    ProjectService.update_license_numbers! project

    project.children.each do |child|
      child.component_whitelist_id = cwl_id
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


end
