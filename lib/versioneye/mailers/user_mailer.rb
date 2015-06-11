class UserMailer < SuperMailer


  def test_email( email )
    m = mail( :to => email, :subject => 'VersionEye Test Email' )
    set_from( m )
  end


  def verification_email(user, verification, email)
    @user  = user
    source = fetch_source( user )
    @verificationlink = "#{Settings.instance.server_url}/users/activate/#{source}/#{verification}"
    m = mail( :to => email, :subject => 'Verification' ) do |format|
      format.html{ render layout: 'email_html_layout' }
    end
    set_from( m )
  end


  def verification_email_only(user, verification, email)
    @user = user
    @verificationlink = "#{Settings.instance.server_url}/users/activate/email/#{verification}"
    m = mail(:to => email, :subject => 'Verification') do |format|
      format.html{ render layout: 'email_html_layout' }
    end
    set_from( m )
  end


  def verification_email_reminder(user, verification, email)
    @user  = user
    source = fetch_source( user )
    @verificationlink = "#{Settings.instance.server_url}/users/activate/#{source}/#{verification}"
    m = mail( :to => email, :subject => 'Verification Reminder' ) do |format|
      format.html{ render layout: 'email_html_layout' }
    end
    set_from( m )
  end


  def collaboration_invitation(collaborator)
    @caller  = collaborator.caller
    @owner   = collaborator.owner
    @project = collaborator.project
    m = mail( :to => collaborator[:invitation_email], :subject => 'Invitation to project collabration' ) do |format|
      format.html{ render layout: 'email_html_layout' }
    end
    set_from( m )
  end


  def new_collaboration( collaborator )
    @caller        = collaborator.caller
    @project       = collaborator.project
    @callee        = collaborator.user
    @collaboration = collaborator
    m = mail( :to => @callee[:email], :subject => "#{@caller[:fullname]} added you as collaborator" ) do |format|
      format.html{ render layout: 'email_html_layout' }
    end
    set_from( m )
  end


  def reset_password(user)
    @user = user
    @url  = "#{Settings.instance.server_url}/updatepassword/#{@user.verification}"
    m = mail(:to => @user.email, :subject => 'Password Reset') do |format|
      format.html{ render layout: 'email_html_layout' }
    end
    set_from( m )
  end


  def new_ticket(user, ticket)
    @fullname = user[:fullname]
    @ticket   = ticket
    m = mail(:to => user[:email], :subject => "VersionEye's lottery confirmation") do |format|
      format.html{ render layout: 'email_html_layout' }
    end
    set_from( m )
  end


  def suggest_packages_email( user )
    @fullname = user[:fullname]
    m = mail(:to => user[:email], :subject => "Follow popular software packages on VersionEye") do |format|
      format.html{ render layout: 'email_html_layout' }
    end
    set_from( m )
  end


  def non_profit_signup( user, np_domain )
    @user = user
    @npd  = np_domain
    m = mail(:to => user[:email], :subject => "You got #{np_domain.free_projects} private projects at VersionEye for free!") do |format|
      format.html{ render layout: 'email_html_layout' }
    end
    set_from( m )
  end


  def fetch_source( user )
    source = "email"
    source = "bitbucket" if user.bitbucket_id
    source = "github"    if user.github_id
    source
  end


end
