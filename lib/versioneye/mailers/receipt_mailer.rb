class ReceiptMailer < ActionMailer::Base

  layout 'email_html_layout'
  default from: "#{Settings.instance.smtp_sender_email}"

  def receipt_email( receipt, pdf )
    @user = receipt.user
    date_str = receipt.invoice_date.strftime("%Y-%M-%d")
    filename = "#{date_str}-VersionEye-#{receipt.receipt_nr}.pdf"
    attachments[filename] = pdf
    mail(:to => @user.email, :subject => "Receipt - #{receipt.receipt_nr}")
  end

end
