class ReceiptMailer < SuperMailer


  def receipt_email( receipt, pdf )
    @receipt = receipt
    email    = fetch_email receipt
    attachments[receipt.filename] = pdf

    m = mail(:to => email, :subject => "Receipt - #{receipt.receipt_nr}") do |format|
      format.html{ render layout: 'email_html_layout' }
    end
    set_from( m )
  end


  private


    def fetch_email receipt
      return receipt.email if !receipt.email.to_s.empty?
      return receipt.organisation.billing_address.email if receipt.organisation && receipt.organisation.billing_address
      return receipt.user.email
    end


end
