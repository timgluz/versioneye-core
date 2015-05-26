class FeedbackMailer < ActionMailer::Base

  layout 'email_html_layout'

  def feedback_email(name, email, feedback)
    @name     = name
    @email    = email
    @feedback = feedback
    rnd_val = create_random_value
    subject = "VersionEye Feedback #{rnd_val}"
    m = mail(:to => 'reiz@versioneye.com', :subject => subject) do |format|
      format.html{ render layout: 'email_html_layout' }
    end
    set_from(m)
  end

  private

    def set_from( mail )
      mail.from = "\"#{Settings.instance.smtp_sender_name}\" <#{Settings.instance.smtp_sender_email}>"
      mail  
    end

    def create_random_value
      chars = '0123456789'
      value = ""
      7.times { value << chars[rand(chars.size)] }
      value
    end

end
