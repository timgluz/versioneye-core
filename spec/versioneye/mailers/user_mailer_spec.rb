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

  describe 'verification_email_reminder' do

    it 'should contain the verification link and a reminder' do

      user = UserFactory.create_new
      verification = "aslaksasasas8888asg8ag"

      email = described_class.verification_email_reminder( user, verification, user.email )

      email.to.should eq( [user.email] )
      email.subject.should eq('Verification Reminder')
      email.encoded.should include( "Hello #{user.fullname}" )
      email.encoded.should include( "#{Settings.instance.server_url}/users/activate/" )
      email.encoded.should include( "#{verification}" )
      email.encoded.should include( "We noticed that you still didn't activate your account." )
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

  describe 'new_ticket' do

    it 'contains the new lottery ticket' do

      user = UserFactory.create_new 1
      prod_1 = ProductFactory.create_new 1
      prod_2 = ProductFactory.create_new 2
      prod_3 = ProductFactory.create_new 3
      ticket = Lottery.new({:user_id => user.id.to_s })
      ticket.selection = []
      ticket.selection << {language: prod_1.language, prod_key: prod_1.prod_key}
      ticket.selection << {language: prod_2.language, prod_key: prod_2.prod_key}
      ticket.selection << {language: prod_3.language, prod_key: prod_3.prod_key}

      email = described_class.new_ticket( user, ticket )

      email.to.should eq( [user.email] )
      email.subject.should eq("VersionEye's lottery confirmation")
      email.encoded.should include( "Hello #{user.fullname}" )
      email.encoded.should include( "Here's your ticket id #{ticket[:_id].to_s}" )
      email.encoded.should include( prod_1.to_param )
      email.encoded.should include( prod_2.to_param )
      email.encoded.should include( prod_3.to_param )
      email.encoded.should include( 'Handelsregister' )

      ActionMailer::Base.deliveries.clear
      email.deliver_now!
      ActionMailer::Base.deliveries.size.should == 1
    end

  end

  describe 'suggest_packages_email' do

    it 'contains suggestions to follow' do

      user = UserFactory.create_new 1

      email = described_class.suggest_packages_email( user )

      email.to.should eq( [user.email] )
      email.subject.should eq("Follow popular software packages on VersionEye")
      email.encoded.should include( "Hello #{user.fullname}" )
      email.encoded.should include( "we noticed you signed up for VersionEye.com but didn't follow any libraries yet" )
      email.encoded.should include( "ruby" )
      email.encoded.should include( 'Handelsregister' )

      ActionMailer::Base.deliveries.clear
      email.deliver_now!
      ActionMailer::Base.deliveries.size.should == 1
    end

  end

end
