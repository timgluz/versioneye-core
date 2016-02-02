require 'spec_helper'

describe SubmittedUrlMailer do

  describe 'new_submission_email' do

    it 'should have 1 submitted_url' do

      user = UserFactory.create_new

      submitted_url = SubmittedUrl.new({
        :url => "http://github.com/versioneye/naturalsorter",
        :message => "Its awesome",
        :user_id => user.id.to_s,
        :user_email => user.email
      })

      email = described_class.new_submission_email( submitted_url )

      email.to.should eq( ['reiz@versioneye.com'] )
      email.encoded.should include( "New Submission: #{submitted_url.url} from #{user.fullname}" )
      email.encoded.should include( "Handelsregister" )

      ActionMailer::Base.deliveries.clear
      email.deliver_now!
      ActionMailer::Base.deliveries.size.should == 1
    end

  end

  describe 'approved_url_email' do

    it 'should have 1 approved url' do

      user = UserFactory.create_new

      submitted_url = SubmittedUrl.new({
        :url => "http://github.com/versioneye/naturalsorter",
        :message => "Its awesome",
        :user_id => user.id.to_s,
        :user_email => user.email,
        :declined => false
      })

      email = described_class.approved_url_email( submitted_url )

      email.to.should eq( [ submitted_url.user.email ] )
      email.encoded.should include( "Your submitted URL #{submitted_url.url} was approved" )
      email.encoded.should include( "Handelsregister" )

      ActionMailer::Base.deliveries.clear
      email.deliver_now!
      ActionMailer::Base.deliveries.size.should == 1
    end

  end

  describe 'declined_url_email' do

    it 'should have 1 declined url' do

      user = UserFactory.create_new

      submitted_url = SubmittedUrl.new({
        :url => "http://github.com/versioneye/naturalsorter",
        :message => "Its awesome",
        :user_id => user.id.to_s,
        :user_email => user.email,
        :declined => true
      })

      email = described_class.declined_url_email( submitted_url )

      email.to.should eq( [ submitted_url.user.email ] )
      email.encoded.should include( "Your submitted URL #{submitted_url.url} is declined" )
      email.encoded.should include( "Handelsregister" )

      ActionMailer::Base.deliveries.clear
      email.deliver_now!
      ActionMailer::Base.deliveries.size.should == 1
    end

  end

  describe 'integrated_url_email' do

    it 'should have 1 existing url' do

      user    = UserFactory.create_new
      product = ProductFactory.create_new

      submitted_url = SubmittedUrl.new({
        :url => "http://github.com/versioneye/naturalsorter",
        :message => "Its awesome",
        :user_id => user.id.to_s,
        :user_email => user.email,
        :declined => false
      })

      email = described_class.integrated_url_email( submitted_url, product )

      email.to.should eq( [ submitted_url.user.email ] )
      email.encoded.should include( "Your submitted URL #{submitted_url.url} is now successfully integrated to our page" )
      email.encoded.should include( "You can find more information on the package page" )
      email.encoded.should include( "#{Settings.instance.server_url}/#{product.language_esc}/#{product.to_param}" )
      email.encoded.should include( "Handelsregister" )

      ActionMailer::Base.deliveries.clear
      email.deliver_now!
      ActionMailer::Base.deliveries.size.should == 1
    end

  end

end
