require 'spec_helper'

describe SubscriptionMailer do

  describe 'update_subscription' do

    it 'should have the new plan' do

      Plan.create_defaults
      plan = Plan.medium

      orga = Organisation.new({:name => "test_orga"})
      orga.plan = plan
      expect( orga.save ).to be_truthy

      ba = orga.fetch_or_create_billing_address
      ba.name = 'test'
      ba.email = 'test@test.de'
      ba.street = "test"
      ba.zip = '48123'
      ba.city = 'Mannheim'
      ba.country = 'DE'
      expect( ba.save ).to be_truthy

      email = described_class.update_orga_subscription( orga )

      email.to.should eq( [ba.email] )
      email.encoded.should include( "You just updated your subscription to the plan \"#{plan.name}\"" )
      email.encoded.should include( "Handelsregister" )

      ActionMailer::Base.deliveries.clear
      email.deliver_now!
      ActionMailer::Base.deliveries.size.should == 1
    end

  end

end
