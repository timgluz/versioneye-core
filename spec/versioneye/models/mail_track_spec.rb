require 'spec_helper'

describe MailTrack do

  describe "fetch_by" do

    it "finds the right one" do
      expect( MailTrack.add '777', 'email', 'daily', '1' ).to be_truthy

      expect( MailTrack.fetch_by('777', 'email', 'daily').count ).to eq(1)
      expect( MailTrack.send_already? '777', 'email', 'daily' ).to be_truthy
    end
    it "doesnt find because older than 24 hours" do
      yesterday = DateTime.now - 25.hours
      mt = MailTrack.new(:user_id => '777', :template => 'email', :period => 'daily', :project_id => '1', :created_at => yesterday)
      expect( mt.save ).to be_truthy

      expect( MailTrack.fetch_by('777', 'email', 'daily').count ).to eq(0)
      expect( MailTrack.send_already? '777', 'email', 'daily' ).to be_falsey
    end
    it "doesnt exist already" do
      expect( MailTrack.fetch_by('777', 'email', 'daily').count ).to eq(0)
      expect( MailTrack.send_already? '777', 'email', 'daily' ).to be_falsey
    end
    it "exist already for weekkly" do
      days_ago = DateTime.now - 2.days
      mt = MailTrack.new(:user_id => '777', :template => 'email', :period => 'weekly', :project_id => '1', :created_at => days_ago)
      expect( mt.save ).to be_truthy

      expect( MailTrack.fetch_by('777', 'email', 'weekly').count ).to eq(1)
      expect( MailTrack.send_already? '777', 'email', 'weekly' ).to be_truthy
    end
    it "exist already for monthly" do
      weeks_ago = DateTime.now - 3.weeks
      mt = MailTrack.new(:user_id => '777', :template => 'email', :period => 'monthly', :project_id => '1', :created_at => weeks_ago)
      expect( mt.save ).to be_truthy

      expect( MailTrack.fetch_by('777', 'email', 'monthly').count ).to eq(1)
      expect( MailTrack.send_already? '777', 'email', 'monthly' ).to be_truthy
    end

  end

end
