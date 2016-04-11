require 'spec_helper'

describe NotificationWatcher do

  before(:each) do
    User.destroy_all
    Product.destroy_all
  end

  describe "save" do

    it "saves with constraints" do
      nw = NotificationWatcher.new({:name => 'watcher1', :event => 'security', :type => 'email'})
      expect(nw.save).to be_truthy

      nwc = NotificationWatcherConstraint.new({ :type => 'wildcard', :value => '**/*.jar' })
      nwc.notification_watcher = nw
      expect(nwc.save).to be_truthy

      nwc = NotificationWatcherConfig.new({ :email => 'hi@ho.do' })
      nwc.notification_watcher = nw
      expect(nwc.save).to be_truthy

      nw.reload
      expect(nw.constraints.count).to eq(1)
      expect( nw.config.ids ).to eq(nwc.ids)
    end

  end

end
