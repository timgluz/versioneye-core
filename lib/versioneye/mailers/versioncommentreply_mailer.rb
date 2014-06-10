class VersioncommentreplyMailer < ActionMailer::Base

  layout 'email_html_layout'
  default from: "\"#{Settings.instance.smtp_sender_name}\" <#{Settings.instance.smtp_sender_email}>"

  def versioncomment_reply_email(comment_user, reply_user, comment)
    @comment_user = comment_user
    @reply_user   = reply_user
    @comment      = comment
    @prod         = comment.product
    @commentlink = "#{Settings.instance.server_url}/vc/#{comment.id}"
    mail(
      :to => @comment_user.email,
      :subject => "#{reply_user.fullname} replied to your comment",
      :tag => 'versioncomment'
      )
  end

end
