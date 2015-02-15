require 'spec_helper'

describe NotificationService do

  before(:each) do
    User.destroy_all
    Product.destroy_all
    Notification.destroy_all

    @user         = UserFactory.create_new 1
    @notification = NotificationFactory.create_new @user
  end

  describe "remove_notifications" do

    it "fetches all unsent_user_notifications" do
      notifications = Notification.unsent_user_notifications @user
      notifications.should_not be_nil
      notifications.size.should eq(1)
      notifications.first.user_id.should eq( @user.id )

      NotificationService.remove_notifications( @user )
      notifications = Notification.unsent_user_notifications @user
      notifications.should_not be_nil
      notifications.size.should eq(0)
    end

  end

  describe "send_notifications" do

    it "sends out 2 notifications" do
      user = UserFactory.create_new 2
      User.count.should eq(2)

      notification = NotificationFactory.create_new user

      notification.user_id.should_not be_nil
      notification.user.should_not be_nil

      Notification.count.should eq(2)

      count = NotificationService.send_notifications
      count.should eq(2)
    end

    it "sends out 1 out of 2 notifications, because 1 user is deleted" do
      user         = UserFactory.create_new 3
      NotificationFactory.create_new user
      user.deleted_user = true
      user.save
      count        = NotificationService.send_notifications
      count.should eq(1)
    end

    it "sends out 1 out of 2 notifications, because 1 user has inactive email" do
      user         = UserFactory.create_new 3
      NotificationFactory.create_new user
      user.email_inactive = true
      user.save
      count = NotificationService.send_notifications
      count.should eq(1)
    end

    it "sends out 0 notifications, because emails are turned off" do
      uns = UserNotificationSetting.fetch_or_create_notification_setting @user
      uns.notification_emails = false
      uns.save
      Notification.count.should == 1
      Notification.first.sent_email.should be_falsey
      Notification.first.email_disabled.should be_falsey
      count = NotificationService.send_notifications
      count.should eq(0)
      Notification.count.should == 1
      Notification.first.sent_email.should be_truthy
      Notification.first.email_disabled.should be_truthy
    end

    it "sends out 2 out of 3 because of uniq prods" do
      uns = UserNotificationSetting.fetch_or_create_notification_setting @user
      uns.notification_emails = true 
      uns.save
      
      random_product = ProductFactory.create_new(Random.rand(778811), :gemfile)
      noti_1 = Notification.new  user_id: @user.id,
                                    product_id: random_product.id,
                                    version_id: random_product.version
      noti_1.save 
      noti_2 = Notification.new  user_id: @user.id,
                                    product_id: random_product.id,
                                    version_id: '0.1.2'
      noti_2.save 

      Notification.count.should == 3
      Notification.where(:email_disabled => true).count.should eq(0)
      count = NotificationService.send_notifications
      count.should eq(1)
      Notification.where(:email_disabled => true).count.should eq(0)
    end

  end

end
