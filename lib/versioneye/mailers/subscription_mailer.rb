class SubscriptionMailer < ActionMailer::Base

  layout 'email_html_layout'
  default from: "\"#{Settings.instance.smtp_sender_name}\" <#{Settings.instance.smtp_sender_email}>"

  def update_subscription( user )
    @user =  user
    mail(to: user.email, subject: 'VersionEye Subscription') do |format|
      format.html{ render layout: 'email_html_layout' }
    end
  end

end
