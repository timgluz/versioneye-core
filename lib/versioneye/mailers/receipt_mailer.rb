class ReceiptMailer < ActionMailer::Base

  layout 'email_html_layout'
  default from: "\"#{Settings.instance.smtp_sender_name}\" <#{Settings.instance.smtp_sender_email}>"

  def receipt_email( receipt, pdf )
    @user = receipt.user
    email = fetch_email receipt
    attachments[receipt.filename] = pdf
    mail(:to => email, :subject => "Receipt - #{receipt.receipt_nr}")
  end

  private

    def fetch_email receipt
      return receipt.email if !receipt.email.to_s.empty?
      return receipt.user.email
    end

end
