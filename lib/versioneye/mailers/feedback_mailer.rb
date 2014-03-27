class FeedbackMailer < ActionMailer::Base

  layout 'email_html_layout'
  default from: "\"VersionEye\" <notify@versioneye.com>"

  def feedback_email(name, email, feedback)
    @name     = name
    @email    = email
    @feedback = feedback
    mail(:to => 'reiz@versioneye.com', :subject => 'VersionEye Feedback') do |format|
      format.html{ render layout: 'email_html_layout' }
    end
  end

end
