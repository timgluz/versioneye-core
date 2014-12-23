class NewsletterMailer < ActionMailer::Base

  layout 'email_html_layout'
  default from: "\"#{Settings.instance.smtp_sender_name}\" <#{Settings.instance.smtp_sender_email}>"

  def newsletter_new_features_email(user)
    @user = user
    mail(:to => @user.email, :subject => 'Mary Christmas - Multiple Files per Project!') do |format|
      format.html{ render layout: 'email_html_layout' }
    end
  end

end
