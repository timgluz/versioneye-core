require 'spec_helper'

describe Receipt do

  before(:each) do
    Plan.create_defaults
    @user = User.new({:fullname => 'Hans Tanz', :username => 'hanstanz',
      :email => 'hans@tanz.de', :password => 'password', :salt => 'salt',
      :terms => true, :datenerhebung => true})
    @user.save
    @orga = OrganisationService.create_new_for @user
    expect( @orga.save ).to be_truthy
  end

  describe 'taxid_mandatory?' do

    it 'returns true for company in DE' do
      receipt = Receipt.new({:country => 'DE', :type => Receipt::A_TYPE_CORPORATE })
      expect( receipt.taxid_mandatory?() ).to be_truthy
    end
    it 'returns false for individual in DE' do
      receipt = Receipt.new({:country => 'DE', :type => Receipt::A_TYPE_INDIVIDUAL })
      expect( receipt.taxid_mandatory?() ).to be_falsey
    end

    it 'returns true for company in GB' do
      receipt = Receipt.new({:country => 'GB', :type => Receipt::A_TYPE_CORPORATE })
      expect( receipt.taxid_mandatory?() ).to be_truthy
    end
    it 'returns false for individual in GB' do
      receipt = Receipt.new({:country => 'GB', :type => Receipt::A_TYPE_INDIVIDUAL })
      expect( receipt.taxid_mandatory?() ).to be_falsey
    end

    it 'returns false for company in US' do
      receipt = Receipt.new({:country => 'US', :type => Receipt::A_TYPE_CORPORATE })
      expect( receipt.taxid_mandatory?() ).to be_falsey
    end
    it 'returns false for individual in US' do
      receipt = Receipt.new({:country => 'US', :type => Receipt::A_TYPE_INDIVIDUAL })
      expect( receipt.taxid_mandatory?() ).to be_falsey
    end

  end

  describe "save" do

    it 'does not save becaue company is missing' do
      receipt = described_class.new
      ba = BillingAddressFactory.create_new @orga
      invoice = StripeInvoiceFactory.create_new
      receipt.update_from_billing_address ba
      receipt.update_from_invoice invoice
      receipt.invoice_id = 'tx_1'
      receipt.receipt_nr = 1
      receipt.type = Receipt::A_TYPE_CORPORATE
      receipt.country = 'DE'
      receipt.company = nil
      receipt.taxid = 'DE08585'
      expect( receipt.save ).to be_falsey
    end

    it 'does not save becaue taxid is missing' do
      receipt = described_class.new
      ba = BillingAddressFactory.create_new @orga
      invoice = StripeInvoiceFactory.create_new
      receipt.update_from_billing_address ba
      receipt.update_from_invoice invoice
      receipt.invoice_id = 'tx_1'
      receipt.receipt_nr = 1
      receipt.type = Receipt::A_TYPE_CORPORATE
      receipt.country = 'DE'
      receipt.taxid = nil
      expect( receipt.save ).to be_falsey
    end

    it 'does save becaue taxid is there' do
      receipt = described_class.new()
      ba = BillingAddressFactory.create_new @orga
      invoice = StripeInvoiceFactory.create_new
      receipt.update_from_billing_address ba
      receipt.update_from_invoice invoice
      receipt.invoice_id = 'tx_1'
      receipt.receipt_nr = 1
      receipt.type = Receipt::A_TYPE_CORPORATE
      receipt.country = 'DE'
      receipt.taxid = 'DE1234'
      receipt.organisation = @orga
      receipt.plan = @orga.plan
      receipt.save
      expect( receipt.save ).to be_truthy
    end

    it 'does not save becaue receipt_nr is missing' do
      ba = BillingAddressFactory.create_new @orga
      invoice = StripeInvoiceFactory.create_new
      receipt = described_class.new
      receipt.update_from_billing_address ba
      receipt.update_from_invoice invoice
      receipt.invoice_id = 'tx_1'
      expect( receipt.save ).to be_falsey
    end

    it 'does save becaue receipt_nr is there' do
      ba = BillingAddressFactory.create_new @orga
      invoice = StripeInvoiceFactory.create_new
      receipt = described_class.new
      receipt.update_from_billing_address ba
      receipt.update_from_invoice invoice
      receipt.invoice_id = 'tx_1'
      receipt.receipt_nr = 1
      receipt.organisation = @orga
      receipt.plan = @orga.plan
      expect( receipt.save ).to be_truthy
    end

    it 'saves the first one and skips the 2nd because of same receipt_nr' do
      ba = BillingAddressFactory.create_new @orga
      invoice = StripeInvoiceFactory.create_new

      receipt = described_class.new

      receipt.update_from_billing_address ba
      receipt.update_from_invoice invoice
      receipt.receipt_nr = 1
      receipt.invoice_id = 'tx_1'
      receipt.organisation = @orga
      receipt.plan = @orga.plan
      expect( receipt.save ).to be_truthy

      receipt_2 = described_class.new
      receipt_2.update_from_billing_address ba
      receipt_2.update_from_invoice invoice
      receipt_2.receipt_nr = 1
      receipt_2.invoice_id = 'tx_2'
      receipt_2.organisation = @orga
      receipt_2.plan = @orga.plan
      expect( receipt_2.save ).to be_falsey
      expect( receipt_2.filename ).to eq(receipt_2.to_s)
    end

    it 'saves both' do
      ba = BillingAddressFactory.create_new @orga
      invoice = StripeInvoiceFactory.create_new

      receipt = described_class.new

      receipt.update_from_billing_address ba
      receipt.update_from_invoice invoice
      receipt.receipt_nr = 1
      receipt.invoice_id = 'tx_1'
      receipt.organisation = @orga
      receipt.plan = @orga.plan
      expect( receipt.save ).to be_truthy

      receipt_2 = described_class.new
      receipt_2.update_from_billing_address ba
      receipt_2.update_from_invoice invoice
      receipt_2.receipt_nr = 2
      receipt_2.invoice_id = 'tx_2'
      receipt_2.organisation = @orga
      receipt_2.plan = @orga.plan
      expect( receipt_2.save ).to be_truthy
    end

  end

  describe "update_from_billing_address" do

    it "updates from billing address" do
      ba = BillingAddressFactory.create_new @orga
      invoice = StripeInvoiceFactory.create_new

      receipt = described_class.new

      expect( receipt.name ).to be_nil
      expect( receipt.street ).to be_nil
      expect( receipt.zip ).to be_nil
      expect( receipt.city ).to be_nil
      expect( receipt.company ).to be_nil
      expect( receipt.taxid ).to be_nil

      receipt.update_from_billing_address ba
      receipt.update_from_invoice invoice

      expect( receipt.name ).to eq('Hans Meier')
      expect( receipt.street ).to eq('Hansestrasse 112')
      expect( receipt.zip ).to eq('12345')
      expect( receipt.city ).to eq('Hamburg')
      expect( receipt.country ).to eq('DE')
      expect( receipt.company ).to eq('HanseComp')
      expect( receipt.taxid ).to eq('DE12345')
    end

  end

  describe 'tax_free' do
    it 'is false for DE' do
      receipt = described_class.new({:country => 'DE'})
      expect( receipt.tax_free ).to be_falsey
    end
    it 'is false for FR' do
      receipt = described_class.new({:country => 'FR'})
      expect( receipt.tax_free ).to be_falsey
    end
    it 'is false for FR' do
      receipt = described_class.new({:country => 'GB'})
      expect( receipt.tax_free ).to be_falsey
    end
    it 'is true for US' do
      receipt = described_class.new({:country => 'US'})
      expect( receipt.tax_free ).to be_truthy
    end
  end

  describe 'taxable' do
    it 'is true for DE' do
      receipt = described_class.new({:country => 'DE', :type => Receipt::A_TYPE_INDIVIDUAL})
      expect( receipt.taxable ).to be_truthy
      receipt = described_class.new({:country => 'DE', :type => Receipt::A_TYPE_CORPORATE})
      expect( receipt.taxable ).to be_truthy
    end
    it 'is false for individual in FR' do
      receipt = described_class.new({:country => 'FR', :type => Receipt::A_TYPE_INDIVIDUAL})
      expect( receipt.taxable ).to be_falsey
    end
    it 'is false for companies in FR' do
      receipt = described_class.new({:country => 'FR', :type => Receipt::A_TYPE_CORPORATE})
      expect( receipt.taxable ).to be_falsey
    end
    it 'is false for US' do
      receipt = described_class.new({:country => 'US'})
      expect( receipt.taxable ).to be_falsey
    end
  end

  describe 'reverse_charge' do
    it 'is false for DE' do
      receipt = described_class.new({:country => 'DE', :type => Receipt::A_TYPE_INDIVIDUAL})
      expect( receipt.reverse_charge ).to be_falsey
      receipt = described_class.new({:country => 'DE', :type => Receipt::A_TYPE_CORPORATE})
      expect( receipt.reverse_charge ).to be_falsey
    end
    it 'is true for individual in FR' do
      receipt = described_class.new({:country => 'FR', :type => Receipt::A_TYPE_INDIVIDUAL})
      expect( receipt.reverse_charge ).to be_falsey
    end
    it 'is false for companies in FR' do
      receipt = described_class.new({:country => 'FR', :type => Receipt::A_TYPE_CORPORATE})
      expect( receipt.reverse_charge ).to be_truthy
    end
    it 'is false for US' do
      receipt = described_class.new({:country => 'US'})
      expect( receipt.reverse_charge ).to be_falsey
    end
  end

  describe 'get_binding' do
    it 'returns not nil' do
      receipt = described_class.new({:country => 'US'})
      expect( receipt.get_binding ).to_not be_nil
    end
  end

end
