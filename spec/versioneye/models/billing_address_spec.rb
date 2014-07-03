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
      params[:country] = 'DE'
      params[:taxid] = 'HansVat'

      ba = described_class.new
      ba.name.should be_nil
      ba.company.should be_nil
      ba.street.should be_nil
      ba.zip.should be_nil
      ba.city.should be_nil
      ba.country.should be_nil
      ba.taxid.should be_nil
      ba.save.should be_falsey

      ba.update_from_params params

      ba.name.should eq('Hans')
      ba.company.should eq('HansImGlueck')
      ba.street.should eq('HansStrasse 777')
      ba.zip.should eq('12345')
      ba.city.should eq('HansCity')
      ba.country.should eq('DE')
      ba.taxid.should eq('HansVat')
      ba.save.should be_truthy
    end

  end

  describe 'save' do

    it 'doesnt save because company is missing for coroporate type' do
      ba = described_class.new
      params = Hash.new
      params[:type]     = BillingAddress::A_TYPE_CORPORATE
      params[:name]     = 'Hans'
      params[:street]   = 'HansStrasse 777'
      params[:zip_code] = '12345'
      params[:city]     = 'HansCity'
      params[:country]  = 'DE'
      ba.update_from_params params
      ba.save.should be_falsey
    end

    it 'saves because company is coroporate type and has company name' do
      ba = described_class.new
      params = Hash.new
      params[:type]     = BillingAddress::A_TYPE_CORPORATE
      params[:name]     = 'Hans'
      params[:street]   = 'HansStrasse 777'
      params[:zip_code] = '12345'
      params[:city]     = 'HansCity'
      params[:country]  = 'DE'
      params[:company]  = 'HansImGlueck'
      params[:taxid]    = 'DE87473'
      ba.update_from_params params
      resp = ba.save
      resp.should be_truthy
    end

    it 'doesnt save because taxid is missing for coroporate type' do
      ba = described_class.new
      params = Hash.new
      params[:type]     = BillingAddress::A_TYPE_CORPORATE
      params[:name]     = 'Hans'
      params[:street]   = 'HansStrasse 777'
      params[:zip_code] = '12345'
      params[:city]     = 'HansCity'
      params[:country]  = 'DE'
      params[:company]  = 'HansImGlueck'
      ba.update_from_params params
      ba.save.should be_falsey
    end

    it 'saves because type is individual, company is not mandatory' do
      ba = described_class.new
      params = Hash.new
      params[:type]     = BillingAddress::A_TYPE_INDIVIDUAL
      params[:name]     = 'Hans'
      params[:street]   = 'HansStrasse 777'
      params[:zip_code] = '12345'
      params[:city]     = 'HansCity'
      params[:country]  = 'DE'
      ba.update_from_params params
      ba.save.should be_truthy
    end

    it 'does not save because country is wrong' do
      ba = described_class.new
      params = Hash.new
      params[:type]     = BillingAddress::A_TYPE_INDIVIDUAL
      params[:name]     = 'Hans'
      params[:street]   = 'HansStrasse 777'
      params[:zip_code] = '12345'
      params[:city]     = 'HansCity'
      params[:country]  = 'DD'
      ba.update_from_params params
      ba.save.should be_falsey
    end

  end

end
