require 'spec_helper'

describe VersioncommentMailer do

  describe 'versioncomment_email' do

    it 'should have the comment inside' do
      user     = UserFactory.create_new
      follower = UserFactory.create_new
      product  = ProductFactory.create_new
      comment  = Versioncomment.new({:user_id => user.id.to_s,
        :product_key => product.prod_key, :language => product.language,
        :version => product.version, :prod_name => product.name,
        :comment => 'This is awesome' })
      comment.save
      commentlink = "#{Settings.instance.server_url}/vc/#{comment.id}"

      email = described_class.versioncomment_email( product, follower, user, comment )

      email.to.should eq( [follower.email] )
      email.encoded.should include( "Hello #{follower.fullname}" )
      email.encoded.should include( user.username )
      email.encoded.should include( "wrote a comment" )
      email.encoded.should include( product.to_param )
      email.encoded.should include( commentlink )
      email.encoded.should include( "Handelsregister" )

      ActionMailer::Base.deliveries.clear
      email.deliver_now!
      ActionMailer::Base.deliveries.size.should == 1
    end

  end

end
