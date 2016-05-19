class OrganisationService < Versioneye::Service


  def self.create_new user, name
    if !Organisation.where({:name => name.downcase}).empty?
      raise "Organisation with name '#{name}' exists already. Please choose another name."
    end
    orga = Organisation.new({:name => name.downcase})
    orga.save
    team = Team.new(:name => Team::A_OWNERS)
    team.add_member user
    team.organisation = orga
    team.save
    orga
  end


  def self.delete orga
    return false if orga.nil?

    orga.projects.each do |project|
      ProjectService.destroy project
    end

    orga.teams.each do |team|
      TeamService.delete team
    end

    orga.license_whitelists.each do |lwl|
      lwl.delete
    end

    orga.component_whitelists.each do |cwl|
      cwl.delete
    end

    orga.delete
  end


  def self.owner? orga, user
    return false if orga.nil? || user.nil?

    team = Team.where(:organisation_id => orga.ids, :name => Team::A_OWNERS).first
    return false if team.nil?

    team.members.each do |member|
      return true if member.user.ids.eql?(user.ids)
    end
    false
  end


  def self.member? orga, user
    return false if orga.nil? || user.nil?

    orga.teams.each do |team|
      team.members.each do |member|
        return true if member.user.ids.eql?(user.ids)
      end
    end
    false
  end


  def self.allowed_to_transfer_projects? orga, user
    return false if orga.nil? || user.nil?
    return false if !member?( orga, user )
    return true  if owner?( orga, user )
    return true  if orga.mattp == true
    return false
  end

  def self.allowed_to_assign_teams? orga, user
    return false if orga.nil? || user.nil?
    return false if !member?( orga, user )
    return true  if owner?( orga, user )
    return true  if orga.matattp == true
    return false
  end


  # Attach a project to the organisation
  def self.transfer project, organisation
    return false if organisation.nil? || project.nil?

    project.organisation = organisation
    project.teams = [organisation.owner_team]
    project.license_whitelist_id = organisation.default_lwl_id
    project.component_whitelist_id = organisation.default_cwl_id
    result = project.save
    if result == true && ( !project.license_whitelist_id.nil? || !project.component_whitelist_id.nil? )
      ProjectUpdateService.update_async project
    end
    return result
  end


  # Returns all organisations there the given user
  # is member in. If `only_owners` is true, only the
  # organisations are returned there the given user
  # is in the owner team.
  def self.index user, only_owners = false
    return Organisation.all if user.admin == true

    tms = TeamMember.where(:user_id => user.ids)
    return [] if tms.empty?

    organisations = []
    orga_ids = []
    tms.each do |tm|
      if tm.team.nil?
        tm.delete
        next
      end
      next if only_owners == true && !tm.team.name.eql?(Team::A_OWNERS)

      orga = tm.team.organisation
      next if orga.nil?
      next if orga_ids.include?(orga.ids)

      orga_ids.push(orga.ids)
      organisations.push(orga)
    end
    organisations
  end


  def self.orgas_allowed_to_transfer user
    organisations = index( user, false )
    orgas = []
    organisations.each do |orga|
      orgas.push(orga) if OrganisationService.allowed_to_transfer_projects?( orga, user )
    end
    orgas
  end


end
