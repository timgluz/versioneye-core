class SubmittedUrlMailer < SuperMailer


  def new_submission_email(submitted_url)
    @base_url = Settings.instance.server_url
    @submitted_url = submitted_url
    @user = submitted_url.user
    m = mail(:to => 'reiz@versioneye.com', :subject => 'New Submission') do |format|
      format.html{ render layout: 'email_html_layout' }
    end
    set_from( m )
  end


  def approved_url_email(submitted_url)
    @submitted_url = submitted_url
    @user = submitted_url.user
    m = mail(:to => @user.email, :subject => 'Your submitted Resource is accepted.') do |format|
      format.html{ render layout: 'email_html_layout' }
    end
    set_from( m )
  end


  def declined_url_email(submitted_url)
    @submitted_url = submitted_url
    @user = submitted_url.user
    m = mail(:to => @user.email, :subject => 'You submitted Resource is declined.') do |format|
      format.html{ render layout: 'email_html_layout' }
    end
    set_from( m )
  end


  def integrated_url_email(submitted_url, product)
    @base_url = Settings.instance.server_url
    @submitted_url = submitted_url
    @user = submitted_url.user
    @product = product
    m = mail(:to => @user.email, :subject => 'Your submitted Resource is integrated') do |format|
      format.html{ render layout: 'email_html_layout' }
    end
    set_from( m )
  end


end
