class TeamNotificationService  < Versioneye::Service

  def self.start
    Plan.all.desc(:prio).each do |plan|
      plan.organisations.each do |orga|
        process_orga( orga )
      end
    end
  end

  def self.process_orga orga
    logger.info "Process orga #{orga.name}"
    update_projects_for orga
    orga.teams.each do |team|
      logger.info " - Process orga #{orga.name} and team #{team.name}"
      projects = orga.team_projects team.ids
      projects.each do |project|
        # TODO notify( orga, team, project )
      end
    end
  end

  def self.update_projects_for orga
    return nil if orga.nil?
    return nil if orga.projects.nil?
    return nil if orga.projects.empty?

    orga.projects.each do |project|
      logger.info " -- Update project #{project.language}/#{project.name}"
      ProjectUpdateService.update project, false
    end
  end

end
