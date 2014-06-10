class ReceiptMailer < ActionMailer::Base

  layout 'email_html_layout'
  default from: "\"#{Settings.instance.smtp_sender_name}\" <#{Settings.instance.smtp_sender_email}>"

  def receipt_email( receipt, pdf )
    @user = receipt.user
    attachments[receipt.filename] = pdf
    mail(:to => @user.email, :subject => "Receipt - #{receipt.receipt_nr}")
  end

end
