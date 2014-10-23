class UserMailer < ActionMailer::Base

  layout 'email_html_layout'
  default from: "\"#{Settings.instance.smtp_sender_name}\" <#{Settings.instance.smtp_sender_email}>"

  def test_email( email )
    mail( :to => email, :subject => 'VersionEye Test Email' )
  end

  def verification_email(user, verification, email)
    @user  = user
    source = fetch_source( user )
    @verificationlink = "#{Settings.instance.server_url}/users/activate/#{source}/#{verification}"
    mail( :to => email, :subject => 'Verification' )
  end

  def verification_email_only(user, verification, email)
    @user = user
    @verificationlink = "#{Settings.instance.server_url}/users/activate/email/#{verification}"
    mail(:to => email, :subject => 'Verification')
  end

  def verification_email_reminder(user, verification, email)
    @user  = user
    source = fetch_source( user )
    @verificationlink = "#{Settings.instance.server_url}/users/activate/#{source}/#{verification}"
    mail( :to => email, :subject => 'Verification Reminder' )
  end

  def collaboration_invitation(collaborator)
    @caller  = collaborator.caller
    @owner   = collaborator.owner
    @project = collaborator.project
    mail( :to => collaborator[:invitation_email], :subject => 'Invitation to project collabration' )
  end

  def new_collaboration(collaborator)
    @caller        = collaborator.caller
    @project       = collaborator.project
    @callee        = collaborator.user
    @collaboration = collaborator
    mail( :to => @callee[:email], :subject => "#{@caller[:fullname]} added you as collaborator" )
  end

  def reset_password(user)
    @user = user
    @url  = "#{Settings.instance.server_url}/updatepassword/#{@user.verification}"
    mail(:to => @user.email, :subject => 'Password Reset')
  end

  def new_ticket(user, ticket)
    @fullname = user[:fullname]
    @ticket   = ticket
    mail(:to => user[:email], :subject => "VersionEye's lottery confirmation")
  end

  def suggest_packages_email( user )
    @fullname = user[:fullname]
    mail(:to => user[:email], :subject => "Follow popular software packages on VersionEye")
  end

  def non_profit_signup( user, np_domain )
    @user = user
    @npd  = np_domain
    mail(:to => user[:email], :subject => "You got #{np_domain.free_projects} private projects at VersionEye for free!")
  end

  def fetch_source( user )
    source = "email"
    source = "bitbucket" if user.bitbucket_id
    source = "github"    if user.github_id
    source
  end

end
