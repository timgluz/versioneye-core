require 'spec_helper'

describe Notification do

  before(:each) do
    User.delete_all
    Product.delete_all
    Notification.delete_all

    @user         = UserFactory.create_new 1
    @notification = NotificationFactory.create_new @user
  end

  describe "unsent_user_notifications" do

    it "fetches all unsent notifications" do
      NotificationFactory.create_new @user
      NotificationFactory.create_new @user
      NotificationFactory.create_new @user
      notifications = Notification.unsent_user_notifications @user
      notifications.should_not be_nil
      notifications.size.should eq(4)
    end

  end

end
