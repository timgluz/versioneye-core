class VersioncommentreplyMailer < SuperMailer


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


end
