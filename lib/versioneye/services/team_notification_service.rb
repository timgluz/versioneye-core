class TeamNotificationService  < Versioneye::Service


  def self.start serial = true
    Plan.all.desc(:prio).each do |plan|
      plan.organisations.each do |orga|
        if serial
          process_orga( orga )
        else
          TeamNotificationProducer.new(orga.ids)
        end
      end
    end
  end


  def self.process_orga orga
    update_projects orga
    process_teams orga
  end


  def self.process_teams orga
    orga.teams.each do |team|
      process_team orga, team
    end
  end


  def self.process_team orga, team
    p " - Process orga #{orga.name} and team #{team.name}"
    return nil if team.notifications_all_disabled?
    return nil if team.notify_today? == false
    return nil if team.emails.empty?
    return nil if MailTrack.send_team_email_already?(MailTrack::A_TEMPLATE_TEAM_NOTIFICATION, orga.ids, team.ids)

    projects = orga.team_projects team.ids
    return nil if projects.nil? || projects.empty?

    TeamMailer.team_notification( orga, team, projects ).deliver_now
    MailTrack.add_team MailTrack::A_TEMPLATE_TEAM_NOTIFICATION, orga.ids, team.ids, projects.map(&:ids)
  end


  def self.update_projects orga
    return nil if orga.nil?
    return nil if orga.projects.nil?
    return nil if orga.projects.empty?

    orga.projects.each do |project|
      next if project_processed?( orga, project )

      p " -- Update project #{project.language}/#{project.name}"
      ProjectUpdateService.update project
    end
    p " -- All projects updated for orga #{orga.name}"
  end


  private


    def self.project_processed?( orga, project )
      project.teams.each do |team|
        return true if MailTrack.send_team_email_already?(MailTrack::A_TEMPLATE_TEAM_NOTIFICATION, orga.ids, team.ids)
      end
      false
    end


end
