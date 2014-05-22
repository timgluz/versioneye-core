require 'spec_helper'

describe BillingAddress do

  describe "update_from_params" do

    it "updates from params" do
      params = Hash.new
      params[:name] = 'Hans'
      params[:company] = 'HansImGlueck'
      params[:street] = 'HansStrasse 777'
      params[:zip_code] = '12345'
      params[:city] = 'HansCity'
      params[:country] = 'HansLand'
      params[:vat] = 'HansVat'

      ba = described_class.new
      ba.name.should be_nil
      ba.company.should be_nil
      ba.street.should be_nil
      ba.zip.should be_nil
      ba.city.should be_nil
      ba.country.should be_nil
      ba.vat.should be_nil
      ba.save.should be_false

      ba.update_from_params params

      ba.name.should eq('Hans')
      ba.company.should eq('HansImGlueck')
      ba.street.should eq('HansStrasse 777')
      ba.zip.should eq('12345')
      ba.city.should eq('HansCity')
      ba.country.should eq('HansLand')
      ba.vat.should eq('HansVat')
      ba.save.should be_true
    end

  end

end
