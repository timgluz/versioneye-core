class UserMailer < ActionMailer::Base

  layout 'email_html_layout'
  default from: "\"VersionEye\" <notify@versioneye.com>"

  def receipt_email(user)
    @user = user
    @plan = user.plan
    @billing_address = user.billing_address
    mail(:to => user.email, :subject => 'Receipt')
  end

  def verification_email(user, verification, email)
    @user  = user
    source = fetch_source( user )
    @verificationlink = "#{Settings.instance.server_url_https}/users/activate/#{source}/#{verification}"
    mail( :to => email, :subject => 'Verification' )
  end

  def verification_email_only(user, verification, email)
    @user = user
    @verificationlink = "#{Settings.instance.server_url_https}/users/activate/email/#{verification}"
    mail(:to => email, :subject => 'Verification')
  end

  def verification_email_reminder(user, verification, email)
    @user  = user
    source = fetch_source( user )
    @verificationlink = "#{Settings.instance.server_url_https}/users/activate/#{source}/#{verification}"
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
    @url  = "#{Settings.instance.server_url_https}/updatepassword/#{@user.verification}"
    mail(:to => @user.email, :subject => 'Password Reset')
  end

  def new_user_email(user)
    @user = user
    mail( :to => "reiz@versioneye.com", :subject => "New User" )
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

  def fetch_source( user )
    source = "email"
    source = "bitbucket" if user.bitbucket_id
    source = "github"    if user.github_id
    source
  end

end
