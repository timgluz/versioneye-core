require 'spec_helper'

describe LicenseSuggestion do

  describe 'approve!' do

    it 'approves' do
      ls = LicenseSuggestion.new({:language => 'Ruby', :prod_key => 'rails',
        :version => '1.0.0', :name => 'MIT', :url => 'source', :comments => 'comm'})
      expect( ls.save ).to be_truthy
      expect( LicenseSuggestion.count ).to eq(1)
      expect( LicenseSuggestion.where(:approved => false).count ).to eq(1)
      expect( LicenseSuggestion.unapproved.count ).to eq(1)
      expect( License.count ).to eq( 0 )
      expect( ls.approve! ).to be_truthy
      expect( License.count ).to eq( 1 )
      expect( ls.approve! ).to be_falsey
      expect( License.count ).to eq( 1 )
      expect( LicenseSuggestion.where(:approved => true).count ).to eq(1)
      expect( LicenseSuggestion.unapproved.count ).to eq(0)
    end

  end

end
