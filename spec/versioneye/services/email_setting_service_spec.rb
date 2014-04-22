require 'spec_helper'

describe EmailSettingService do

  describe 'email_setting' do
    it 'returns a new email_setting' do
      EmailSetting.count.should == 0
      es = EmailSettingService.email_setting
      es.should_not be_nil
      EmailSetting.count.should == 1

      es_db = EmailSettingService.email_setting
      es_db.should_not be_nil
      es_db.id.to_s.should eq(es.id.to_s)
      EmailSetting.count.should == 1
    end
  end

  describe 'update_action_mailer' do
    it 'updates the ActionMailer' do
      es = EmailSettingService.email_setting
      es.address = "hallo.address"
      es.port = 444
      es.username = "udo"
      es.password = "linden"
      es.domain = 'google.com'
      es.save
      EmailSettingService.update_action_mailer es
      ActionMailer::Base.smtp_settings[:address].should eq(es.address)
      ActionMailer::Base.smtp_settings[:port].should eq(es.port)
      ActionMailer::Base.smtp_settings[:user_name].should eq(es.username)
      ActionMailer::Base.smtp_settings[:password].should eq(es.password)
      ActionMailer::Base.smtp_settings[:domain].should eq(es.domain)
    end
  end

  describe 'update_action_mailer_from_db' do
    it 'updates the ActionMailer from db' do
      es = EmailSettingService.email_setting
      es.address = "hallo.address"
      es.port = 444
      es.username = "udo"
      es.password = "linden"
      es.domain = 'google.com'
      es.save
      EmailSettingService.update_action_mailer_from_db
      ActionMailer::Base.smtp_settings[:address].should eq(es.address)
      ActionMailer::Base.smtp_settings[:port].should eq(es.port)
      ActionMailer::Base.smtp_settings[:user_name].should eq(es.username)
      ActionMailer::Base.smtp_settings[:password].should eq(es.password)
      ActionMailer::Base.smtp_settings[:domain].should eq(es.domain)
    end
  end

end
