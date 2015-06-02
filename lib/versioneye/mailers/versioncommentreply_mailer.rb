class VersioncommentreplyMailer < ActionMailer::Base

  layout 'email_html_layout'

  def versioncomment_reply_email(comment_user, reply_user, comment)
    @comment_user = comment_user
    @reply_user   = reply_user
    @comment      = comment
    @prod         = comment.product
    @commentlink = "#{Settings.instance.server_url}/vc/#{comment.id}"
    m = mail(:to => @comment_user.email, :subject => "#{reply_user.fullname} replied to your comment", :tag => 'versioncomment') do |format|
      format.html{ render layout: 'email_html_layout' }
    end
    set_from( m )
  end

  private 

    def set_from( mail )
      mail.from = "\"#{Settings.instance.smtp_sender_name}\" <#{Settings.instance.smtp_sender_email}>"
      mail  
    end

end
