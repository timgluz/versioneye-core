class FeedbackMailer < SuperMailer


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


    def create_random_value
      chars = '0123456789'
      value = ""
      7.times { value << chars[rand(chars.size)] }
      value
    end


end
