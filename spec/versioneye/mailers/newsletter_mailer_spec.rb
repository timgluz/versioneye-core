require 'spec_helper'

describe NewsletterMailer do

  describe 'newsletter_new_features_email' do

    it 'should have the right content' do
      user = UserFactory.create_new
      user.fullname = "Bono Tono"
      email = described_class.newsletter_new_features_email( user )

      email.encoded.should include( "Hey Bono Tono" )
      email.encoded.should include( '68163 Mannheim' )

      ActionMailer::Base.deliveries.clear
      email.deliver_now!
      ActionMailer::Base.deliveries.size.should == 1
    end

  end

end
