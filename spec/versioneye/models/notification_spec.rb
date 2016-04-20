require 'spec_helper'

describe Notification do

  before(:each) do
    User.destroy_all
    Product.destroy_all
    Notification.destroy_all

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


  describe "watcher" do
    it 'will return the right watcher' do
      watcher = Watcher.new({ :name => "test", :user => @user })
      expect( watcher.save ).to be_truthy
      notifcation = NotificationFactory.create_new @user
      notifcation.watcher_id = watcher.ids
      expect( notifcation.save ).to be_truthy
      expect( notifcation.watcher ).to_not be_nil
      expect( notifcation.watcher.ids ).to eq( watcher.ids )
    end
  end

end
