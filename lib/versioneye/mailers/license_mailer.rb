class LicenseMailer < SuperMailer


  def new_license_suggestion( license_suggestion )
    @ls = license_suggestion
    m = mail(:to => 'reiz@versioneye.com', :subject => "New License Suggestion") do |format|
      format.html{ render layout: 'email_html_layout' }
    end
    set_from(m)
  end


end
