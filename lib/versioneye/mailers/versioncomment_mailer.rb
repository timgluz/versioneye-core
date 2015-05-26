class VersioncommentMailer < ActionMailer::Base

  layout 'email_html_layout'

  def versioncomment_email(product, follower, user, comment)
    @prod        = product
    @follower    = follower
    @user        = user
    @commentlink = "#{Settings.instance.server_url}/vc/#{comment.id}"
    m = mail(:to => @follower.email, :subject => 'Comment on Package')
    set_from( m )
  end

  private 

    def set_from( mail )
      mail.from = "\"#{Settings.instance.smtp_sender_name}\" <#{Settings.instance.smtp_sender_email}>"
      mail  
    end

end
