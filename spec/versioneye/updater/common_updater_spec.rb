require 'spec_helper'

describe CommonUpdater do

  describe 'update_old_with_new' do

    it 'updates old project with new values, clears the cache and dont send email' do
      ActionMailer::Base.deliveries.clear
      user = UserFactory.create_new
      old_project = ProjectFactory.default user, 10
      new_project = ProjectFactory.default user, 11

      CommonUpdater.cache.set( old_project.id.to_s, "out-of-date", 21600) # TTL = 6.hour
      CommonUpdater.cache.get( old_project.id.to_s).should_not be_nil

      CommonUpdater.new.update_old_with_new old_project, new_project

      # Expect that cache for project badge is cleared
      CommonUpdater.cache.get( old_project.id.to_s).should be_nil

      # Epcect that 0 emails are send
      ActionMailer::Base.deliveries.size.should == 0
    end

  end

end
