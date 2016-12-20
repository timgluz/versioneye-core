class LeadMailer < SuperMailer


  def new_lead( enterprise_lead )
    @el = enterprise_lead
    subject = "New Lead #{enterprise_lead.name}"
    m = mail(:to => 'reiz@versioneye.com', :subject => subject) do |format|
      format.html{ render layout: 'email_html_layout' }
    end
    set_from(m)
  end


end
