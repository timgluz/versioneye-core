class SubscriptionMailer < SuperMailer


  def update_subscription( user )
    @user =  user
    m = mail(to: user.email, subject: 'VersionEye Subscription') do |format|
      format.html{ render layout: 'email_html_layout' }
    end
    set_from(m)
  end


end
