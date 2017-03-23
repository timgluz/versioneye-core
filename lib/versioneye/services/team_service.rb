class TeamService < Versioneye::Service


  def self.delete team
    return false if team.nil?

    team.members.delete_all
    team.delete
  end


  def self.add team_name, orga_id, username, owner
    orga = Organisation.find orga_id
    team = Team.where(:name => team_name, :organisation_id => orga_id).first
    user = User.find_by_username username
    if user.nil?
      raise "User with username '#{username}' not found."
    end

    team.add_member user
    TeamMailer.add_new_member(orga, team, user, owner).deliver_now
    true
  end


  # Assign a number of projects to a team
  def self.assign orga_id, team_name, project_ids, user, single_assignment = false
    orga = Organisation.find orga_id
    if orga.nil?
      raise "Organisation `#{orga_id}` doesn't exist"
    end

    if !OrganisationService.allowed_to_assign_teams?( orga, user )
      raise "You have to be in the Owners team to do mass assignment."
    end

    team = Team.where(:name => team_name, :organisation_id => orga_id).first
    if team.nil?
      raise "Team `#{team_name}` doesn't exist inside of the #{orga.name} organisation."
    end

    project_ids.each do |project_id|
      add_project_to_team( project_id, orga, team, single_assignment )
    end
    true
  end


  private


    def self.add_project_to_team project_id, orga, team, single_assignment = false
      project = Project.where(:id => project_id, :organisation_id => orga.ids).first
      return nil if project.nil?

      project.teams = [] if single_assignment

      return nil if project.teams.count > 0 &&
                    project.teams.map(&:name).include?(team.name)

      project.teams.push( team )
      project.save

      return nil if project.children.count == 0

      project.children.each do |child|
        child.teams = project.teams
        child.save
      end
    rescue => e
      log.error e.message
      log.error e.backtrace.join("\n")
    end


end
