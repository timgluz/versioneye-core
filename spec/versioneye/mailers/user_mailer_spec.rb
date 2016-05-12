require 'spec_helper'

describe UserMailer do


  describe 'verification_email' do

    it 'should contain the verification link' do
      user = UserFactory.create_new
      verification = "aslaksasasas8888asg8ag"

      email = described_class.verification_email( user, verification, user.email )

      email.to.should eq( [user.email] )
      email.from.should eq( [Settings.instance.smtp_sender_email] )
      email.encoded.should include( "Hello #{user.fullname}" )
      email.encoded.should include( "#{Settings.instance.server_url}/users/activate/" )
      email.encoded.should include( "#{verification}" )
      email.encoded.should include( "Handelsregister" )

      ActionMailer::Base.deliveries.clear
      email.deliver_now!
      ActionMailer::Base.deliveries.size.should == 1
    end

    it 'should contain the verification link' do
      Settings.instance.smtp_sender_email = 'test@bin.go'
      user = UserFactory.create_new
      verification = "aslaksasasas8888asg8ag"

      email = described_class.verification_email( user, verification, user.email )

      email.to.should eq( [user.email] )
      email.from.should eq( ['test@bin.go'] )
      email.encoded.should include( "Hello #{user.fullname}" )
      email.encoded.should include( "#{Settings.instance.server_url}/users/activate/" )
      email.encoded.should include( "#{verification}" )
      email.encoded.should include( "Handelsregister" )

      ActionMailer::Base.deliveries.clear
      email.deliver_now!
      ActionMailer::Base.deliveries.size.should == 1
    end

  end


  describe 'verification_email_only' do

    it 'should contain the verification link' do

      user = UserFactory.create_new
      verification = "aslaksasasas8888asg8ag"

      email = described_class.verification_email_only( user, verification, user.email )

      email.to.should eq( [user.email] )
      email.encoded.should include( "Hello #{user.fullname}" )
      email.encoded.should include( "#{Settings.instance.server_url}/users/activate/email/#{verification}" )
      email.encoded.should include( "Handelsregister" )

      ActionMailer::Base.deliveries.clear
      email.deliver_now!
      ActionMailer::Base.deliveries.size.should == 1
    end

  end


  describe 'reset_password' do

    it 'contain link to update the password' do

      user = UserFactory.create_new 1
      user.verification = 'asfgalsfgasgj988asg87asg'
      user.save

      email = described_class.reset_password( user )

      email.to.should eq( [user.email] )
      email.subject.should eq('Password Reset')
      email.encoded.should include( "You've requested a new password" )
      email.encoded.should include( "#{Settings.instance.server_url}/updatepassword/#{user.verification}" )
      email.encoded.should include( 'Handelsregister' )

      ActionMailer::Base.deliveries.clear
      email.deliver_now!
      ActionMailer::Base.deliveries.size.should == 1
    end

  end


end
