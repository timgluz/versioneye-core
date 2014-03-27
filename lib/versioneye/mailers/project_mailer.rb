class ProjectMailer < ActionMailer::Base

  layout 'email_html_layout'
  default from: "\"VersionEye\" <notify@versioneye.com>"

  # TODO refactor this email. Send only link to project on VersionEye.
  def projectnotification_email( project, user = nil )
    @user = user
    @user = project.user if user.nil?
    @dependencies = Hash.new
    deps  = ProjectService.outdated_dependencies( project )
    deps.each do |dep|
      @dependencies[dep.name] = dep
    end
    @project_name = project.name
    @projectlink  = "#{Settings.instance.server_url}/user/projects/#{project.id}"
    @base_url     = Settings.instance.server_url

    email = user ? user.email : Project.email_for(project, @user)

    mail(:to => email, :subject => "Project Notification for #{project.name}") do |format|
      format.html{ render layout: 'email_html_layout' }
    end
  end

end
