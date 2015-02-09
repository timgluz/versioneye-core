require 'spec_helper'

describe FeedbackMailer do

  describe 'feedback_email' do

    it 'should have the right content' do
      email = described_class.feedback_email( "Hans Tanz", "hans@tanz.de", "VersionEye is awesome" )

      email.encoded.should include( "Hans Tanz" )
      email.encoded.should include( 'VersionEye is awesome' )
      email.encoded.should include( 'Mannheim' )
      email.from.should eq([Settings.instance.smtp_sender_email])

      ActionMailer::Base.deliveries.clear
      email.deliver!
      ActionMailer::Base.deliveries.size.should == 1
    end

  end

end
