class VersioncommentMailer < ActionMailer::Base

  layout 'email_html_layout'
  default from: "\"#{Settings.instance.smtp_sender_name}\" <#{Settings.instance.smtp_sender_email}>"

  def versioncomment_email(product, follower, user, comment)
    @prod        = product
    @follower    = follower
    @user        = user
    @commentlink = "#{Settings.instance.server_url}/vc/#{comment.id}"
    mail(:to => @follower.email, :subject => 'Comment on Package')
  end

end
