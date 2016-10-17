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
      params[:email] = 'ema@ame.de'

      ba = described_class.new
      expect( ba.name) .to be_nil
      expect( ba.company) .to be_nil
      expect( ba.street) .to be_nil
      expect( ba.zip) .to be_nil
      expect( ba.city) .to be_nil
      expect( ba.country) .to be_nil
      expect( ba.taxid) .to be_nil
      expect( ba.save) .to be_falsey

      ba.update_from_params params

      expect( ba.name) .to eq('Hans')
      expect( ba.company) .to eq('HansImGlueck')
      expect( ba.street) .to eq('HansStrasse 777')
      expect( ba.zip) .to eq('12345')
      expect( ba.city) .to eq('HansCity')
      expect( ba.country) .to eq('DE')
      expect( ba.taxid) .to eq('HansVat')
      expect( ba.save) .to be_truthy
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
      expect( ba.save) .to be_falsey
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
      params[:email]    = 'my@mail.de'
      params[:taxid]    = 'DE87473'
      ba.update_from_params params
      resp = ba.save
      expect( resp) .to be_truthy
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
      params[:email]    = 'my@mail.de'
      ba.update_from_params params
      expect( ba.save) .to be_falsey
    end

    it 'saves because type is individual, company is not mandatory' do
      ba = described_class.new
      params = Hash.new
      params[:type]     = BillingAddress::A_TYPE_INDIVIDUAL
      params[:name]     = 'Hans'
      params[:email]    = 'my@mail.de'
      params[:street]   = 'HansStrasse 777'
      params[:zip_code] = '12345'
      params[:city]     = 'HansCity'
      params[:country]  = 'DE'
      ba.update_from_params params
      expect( ba.save) .to be_truthy
    end

    it 'does not save because country is wrong' do
      ba = described_class.new
      params = Hash.new
      params[:type]     = BillingAddress::A_TYPE_INDIVIDUAL
      params[:email]    = 'my@mail.de'
      params[:name]     = 'Hans'
      params[:street]   = 'HansStrasse 777'
      params[:zip_code] = '12345'
      params[:city]     = 'HansCity'
      params[:country]  = 'DD'
      ba.update_from_params params
      expect( ba.save) .to be_falsey
    end

  end

end
