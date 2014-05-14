require 'spec_helper'

describe UserNotificationSetting do

  describe "fetch_or_create_notification_setting" do

    it "creates a new one" do
      user = UserFactory.create_new
      user.user_notification_setting.should be_nil
      UserNotificationSetting.fetch_or_create_notification_setting user
      user.user_notification_setting.should_not be_nil
      UserNotificationSetting.count.should eq(1)
      uns = UserNotificationSetting.first
      uns.user.email.should eql(user.email)
      user_db = User.first
      user_db.user_notification_setting.should_not be_nil
    end

  end

end
