require 'spec_helper'

describe NewsletterService do

  describe "send_newsletter_features" do

    it "sends out 0 because user is deleted" do
      user = UserFactory.create_new
      user.deleted = true
      user.save
      described_class.send_newsletter_features.should eq(0)
    end

    it "sends out 0 because user don't want to receive this email" do
      user = UserFactory.create_new
      UserNotificationSetting.fetch_or_create_notification_setting user
      user_notification_setting = user.user_notification_setting
      user_notification_setting.newsletter_features = false
      user_notification_setting.save
      described_class.send_newsletter_features.should eq(0)
    end

    it "sends out 0 because user don't want to receive this email" do
      user = UserFactory.create_new
      UserNotificationSetting.fetch_or_create_notification_setting user
      user_notification_setting = user.user_notification_setting
      user_notification_setting.newsletter_features = nil
      user_notification_setting.save
      described_class.send_newsletter_features.should eq(0)
    end

    it "sends out 1 because user is not deleted and want to receive the email" do
      UserFactory.create_new
      described_class.send_newsletter_features.should eq(1)
    end

    it "sends out 2" do
      UserFactory.create_new 1
      UserFactory.create_new 2
      described_class.send_newsletter_features.should eq(2)
    end

    it "sends out 2 of 3 because 1 is deleted" do
      user = UserFactory.create_new 1
      user.deleted = true
      user.save
      UserFactory.create_new 2
      UserFactory.create_new 3
      described_class.send_newsletter_features.should eq(2)
    end

  end

end
