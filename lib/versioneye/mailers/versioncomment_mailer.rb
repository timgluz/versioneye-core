class VersioncommentMailer < SuperMailer


  def versioncomment_email(product, follower, user, comment)
    @prod        = product
    @follower    = follower
    @user        = user
    @commentlink = "#{Settings.instance.server_url}/vc/#{comment.id}"
    m = mail(:to => @follower.email, :subject => 'Comment on Package') do |format|
      format.html{ render layout: 'email_html_layout' }
    end
    set_from( m )
  end


end
