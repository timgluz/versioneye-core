require 'spec_helper'

describe Receipt do

  describe "update_from_billing_address" do

    it "updates from billing address" do
      ba = BillingAddress.new({:name => 'Hans Meier',
        :street => 'HanseStrasse 112', :zip => '12345',
        :city => 'Hamburg', :country => 'DE', :company => 'HanseComp',
        :taxid => 'DE12345'})

      receipt = described_class.new

      receipt.name.should be_nil
      receipt.street.should be_nil
      receipt.zip.should be_nil
      receipt.city.should be_nil
      receipt.company.should be_nil
      receipt.taxid.should be_nil

      receipt.update_from_billing_address ba

      receipt.name.should eq('Hans Meier')
      receipt.street.should eq('HanseStrasse 112')
      receipt.zip.should eq('12345')
      receipt.city.should eq('Hamburg')
      receipt.country.should eq('DE')
      receipt.company.should eq('HanseComp')
      receipt.taxid.should eq('DE12345')
    end

  end

end
