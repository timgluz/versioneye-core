class ProjectMailer < SuperMailer


  def projectnotification_email( project, user = nil, unknown_licenses = nil, red_licenses = nil )
    @project_name = project.name
    @projectlink  = "#{Settings.instance.server_url}/user/projects/#{project.id}"
    @base_url     = Settings.instance.server_url
    @user         = user ? user : project.user

    deps  = ProjectService.outdated_dependencies( project, true )
    if unknown_licenses.nil? || red_licenses.nil?
      unknown_licenses = ProjectService.unknown_licenses( project )
      red_licenses     = ProjectService.red_licenses( project )
    end

    @outdated_dependencies_count = 0
    @unknown_licenses_count = 0
    @red_licenses_count = 0

    @outdated_dependencies_count = deps.count if deps && !deps.empty?
    @unknown_licenses_count = unknown_licenses.count if unknown_licenses && !unknown_licenses.empty?
    @red_licenses_count = red_licenses.count if red_licenses && !red_licenses.empty?

    email = user ? user.email : Project.email_for(project, @user)

    m = mail(:to => email, :subject => "Project Notification for #{project.name}") do |format|
      format.html{ render layout: 'email_html_layout' }
    end
    set_from( m )
  end


  def projectnotifications_email user, projects, col_projects, period
    @newsletter = "project_emails"
    @user = user
    @projects = projects
    @col_projects = col_projects
    @period = period
    @projectlink = "#{Settings.instance.server_url}/user/projects"

    m = mail(:to => user.email, :subject => "#{period.capitalize} Project Notifications") do |format|
      format.html{ render layout: 'email_html_layout' }
    end
    set_from( m )
  end


  def security_email user, projects
    @newsletter = "project_emails"
    @user = user
    @projects = projects
    @base_url = Settings.instance.server_url
    m = mail(:to => user.email, :subject => "Security Notifications") do |format|
      format.html{ render layout: 'email_html_layout' }
    end
    set_from( m )
  end


end
