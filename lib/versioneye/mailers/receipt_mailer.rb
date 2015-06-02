class ReceiptMailer < ActionMailer::Base

  layout 'email_html_layout'
  default from: "\"#{Settings.instance.smtp_sender_name}\" <#{Settings.instance.smtp_sender_email}>"

  def receipt_email( receipt, pdf )
    @user = receipt.user
    email = fetch_email receipt
    attachments[receipt.filename] = pdf
    mail(:to => email, :subject => "Receipt - #{receipt.receipt_nr}")

    m = mail(:to => email, :subject => "Receipt - #{receipt.receipt_nr}") do |format|
      format.html{ render layout: 'email_html_layout' }
    end
    set_from( m )
  end

  private

    def set_from( mail )
      mail.from = "\"#{Settings.instance.smtp_sender_name}\" <#{Settings.instance.smtp_sender_email}>"
      mail  
    end

    def fetch_email receipt
      return receipt.email if !receipt.email.to_s.empty?
      return receipt.user.email
    end

end
