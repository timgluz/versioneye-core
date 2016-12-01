class TeamNotificationService  < Versioneye::Service


  def self.start
    Plan.all.desc(:prio).each do |plan|
      plan.organisations.each do |orga|
        update_projects orga
        process_teams orga
      end
    end
  end


  def self.process_teams orga
    orga.teams.each do |team|
      process_team orga, team
    end
  end


  def self.process_team orga, team
    p " - Process orga #{orga.name} and team #{team.name}"
    return nil if team.notifications_all_disabled?

    projects = orga.team_projects team.ids
    return nil if projects.nil? || !projects.empty?

    TeamMailer.team_notification( orga, team, projects )
  end


  def self.update_projects orga
    return nil if orga.nil?
    return nil if orga.projects.nil?
    return nil if orga.projects.empty?

    orga.projects.each do |project|
      p " -- Update project #{project.language}/#{project.name}"
      ProjectUpdateService.update project, false
    end
    p " -- All projects updated for orga #{orga.name}"
  end


end
