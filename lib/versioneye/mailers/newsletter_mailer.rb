class NewsletterMailer < SuperMailer


  def newsletter_new_features_email( user )
    @user = user
    @newsletter = "newsletter_features"
    mail(:to => @user.email, :subject => 'Snyk Security + Kobalt Plugin for Kotlin') do |format|
      format.html{ render layout: 'email_html_layout' }
    end
  end


end
