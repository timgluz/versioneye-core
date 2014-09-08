class ProjectMailer < ActionMailer::Base

  layout 'email_html_layout'
  default from: "\"#{Settings.instance.smtp_sender_name}\" <#{Settings.instance.smtp_sender_email}>"

  # TODO refactor this email. Send only link to project on VersionEye.
  def projectnotification_email( project, user = nil, unknown_licenses = nil, red_licenses = nil )
    @project_name = project.name
    @projectlink  = "#{Settings.instance.server_url}/user/projects/#{project.id}"
    @base_url     = Settings.instance.server_url
    @user         = user ? user : project.user
    @dependencies = Hash.new

    deps  = ProjectService.outdated_dependencies( project, true )
    deps.each do |dep|
      @dependencies[dep.name] = dep
    end

    @unknown = unknown_licenses
    @red     = red_licenses
    if unknown_licenses.nil? || red_licenses.nil?
      @unknown = ProjectService.unknown_licenses( project )
      @red     = ProjectService.red_licenses( project )
    end

    email = user ? user.email : Project.email_for(project, @user)

    mail(:to => email, :subject => "Project Notification for #{project.name}") do |format|
      format.html{ render layout: 'email_html_layout' }
    end
  end

end
