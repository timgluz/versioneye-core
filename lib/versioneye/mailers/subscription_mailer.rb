class SubscriptionMailer < SuperMailer


  def update_orga_subscription( orga )
    @orga = orga
    @billing_address = orga.fetch_or_create_billing_address
    m = mail(to: @billing_address.email, subject: 'VersionEye Subscription') do |format|
      format.html{ render layout: 'email_html_layout' }
    end
    set_from(m)
  end


end
