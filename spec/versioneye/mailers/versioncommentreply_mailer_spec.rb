require 'spec_helper'

describe VersioncommentreplyMailer do

  describe 'versioncomment_reply_email' do

    it 'should have the reply comment inside' do
      comment_user = UserFactory.create_new
      reply_user = UserFactory.create_new
      product  = ProductFactory.create_new
      comment  = Versioncomment.new({:user_id => comment_user.id.to_s,
        :product_key => product.prod_key, :language => product.language,
        :version => product.version, :prod_name => product.name,
        :comment => 'This is awesome' })
      comment.save

      reply = comment.versioncommentreplys.create({ :user_id => reply_user.id.to_s,
        :fullname => "Hano", :username => "hano",
        :comment => "Awesome it is indeed!" })

      commentlink = "#{Settings.instance.server_url}/vc/#{comment.id}"

      email = described_class.versioncomment_reply_email( comment_user, reply_user, comment )

      email.to.should eq( [comment_user.email] )
      email.encoded.should include( "Hello #{comment_user.fullname}" )
      email.encoded.should include( reply_user.username )
      email.encoded.should include( "replied to your comment on" )
      email.encoded.should include( product.to_param )
      email.encoded.should include( commentlink )
      email.encoded.should include( "Handelsregister" )

      ActionMailer::Base.deliveries.clear
      email.deliver_now!
      ActionMailer::Base.deliveries.size.should == 1
    end

  end

end

