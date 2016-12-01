class TeamMailer < SuperMailer


  def add_new_member(orga, team, user, owner)
    @user  = user
    @owner = owner
    @orga  = orga
    @team  = team
    @server_url = Settings.instance.server_url
    m = mail( :to => @user.email, :subject => 'You are added to a Team at VersionEye.' ) do |format|
      format.html{ render layout: 'email_html_layout' }
    end
    set_from( m )
  end


  def team_notification( orga, team, projects )
    @orga = orga
    @team = team
    @projects = projects
    @server_url = Settings.instance.server_url
    @projectlink = "#{Settings.instance.server_url}/user/projects"
    m = mail( :to => team.emails, :subject => "Team notifications for #{orga.name}/#{team.name}" ) do |format|
      format.html{ render layout: 'email_html_layout' }
    end
    set_from( m )
  end


end
