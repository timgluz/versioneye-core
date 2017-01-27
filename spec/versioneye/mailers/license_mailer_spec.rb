require 'spec_helper'

describe LicenseMailer do

  describe 'new_license_suggestion' do

    it 'should have the right content' do
      ls = LicenseSuggestion.new({:language => 'Ruby', :prod_key => 'rails',
        :version => '1.0.0', :name => 'MIT', :url => 'source', :comments => 'comm'})
      email = LicenseMailer.new_license_suggestion( ls )

      email.encoded.should include( "ruby" )
      email.encoded.should include( 'rails' )
      email.encoded.should include( 'Mannheim' )

      ActionMailer::Base.deliveries.clear
      email.deliver_now!
      ActionMailer::Base.deliveries.size.should == 1
    end

  end

end
