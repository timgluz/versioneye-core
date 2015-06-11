class SuperMailer < ActionMailer::Base

  layout 'email_html_layout'
  default from: "\"#{Settings.instance.smtp_sender_name}\" <#{Settings.instance.smtp_sender_email}>"

  private 

    def set_from( mail )
      mail.from = "\"#{Settings.instance.smtp_sender_name}\" <#{Settings.instance.smtp_sender_email}>"
      mail  
    end

end
