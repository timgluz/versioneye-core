require 'spec_helper'

describe SubscriptionMailer do

  describe 'update_subscription' do

    it 'should have the new plan' do

      Plan.create_defaults
      plan = Plan.medium

      user = UserFactory.create_new
      user.plan = plan
      user.save

      email = described_class.update_subscription( user )

      email.to.should eq( [user.email] )
      email.encoded.should include( "You just updated your subscription to the plan \"#{plan.name}\"" )
      email.encoded.should include( "Handelsregister" )

      ActionMailer::Base.deliveries.clear
      email.deliver!
      ActionMailer::Base.deliveries.size.should == 1
    end

  end

end
