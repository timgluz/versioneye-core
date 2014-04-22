class SubmittedUrlMailer < ActionMailer::Base

  layout 'email_html_layout'
  default from: "#{Settings.instance.smtp_sender_email}"

  def new_submission_email(submitted_url)
    @base_url = Settings.instance.server_url
    @submitted_url = submitted_url
    @user = submitted_url.user
    mail(:to => 'reiz@versioneye.com', :subject => 'New Submission')
  end

  def approved_url_email(submitted_url)
    @submitted_url = submitted_url
    @user = submitted_url.user
    mail(:to => @user.email, :subject => 'Your submitted Resource is accepted.')
  end

  def declined_url_email(submitted_url)
    @submitted_url = submitted_url
    @user = submitted_url.user
    mail(:to => @user.email, :subject => 'You submitted Resource is declined.')
  end

  def integrated_url_email(submitted_url, product)
    @base_url = Settings.instance.server_url
    @submitted_url = submitted_url
    @user = submitted_url.user
    @product = product
    mail(:to => @user.email, :subject => 'Your submitted Resource is integrated')
  end

end
