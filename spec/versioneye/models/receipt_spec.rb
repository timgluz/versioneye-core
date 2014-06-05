require 'spec_helper'

describe Receipt do

  describe "save" do

    it 'does not save becaue receipt_nr is missing' do
      ba = BillingAddressFactory.create_new
      invoice = StripeInvoiceFactory.create_new
      receipt = described_class.new
      receipt.update_from_billing_address ba
      receipt.update_from_invoice invoice
      receipt.invoice_id = 'tx_1'
      receipt.save.should be_false
    end

    it 'does save becaue receipt_nr is there' do
      ba = BillingAddressFactory.create_new
      invoice = StripeInvoiceFactory.create_new
      receipt = described_class.new
      receipt.update_from_billing_address ba
      receipt.update_from_invoice invoice
      receipt.invoice_id = 'tx_1'
      receipt.receipt_nr = 1
      receipt.save.should be_true
    end

    it 'saves the first one and skips the 2nd because of same receipt_nr' do
      ba = BillingAddressFactory.create_new
      invoice = StripeInvoiceFactory.create_new

      receipt = described_class.new

      receipt.update_from_billing_address ba
      receipt.update_from_invoice invoice
      receipt.receipt_nr = 1
      receipt.invoice_id = 'tx_1'
      receipt.save.should be_true

      receipt_2 = described_class.new
      receipt_2.update_from_billing_address ba
      receipt_2.update_from_invoice invoice
      receipt_2.receipt_nr = 1
      receipt_2.invoice_id = 'tx_2'
      receipt_2.save.should be_false
    end

    it 'saves both' do
      ba = BillingAddressFactory.create_new
      invoice = StripeInvoiceFactory.create_new

      receipt = described_class.new

      receipt.update_from_billing_address ba
      receipt.update_from_invoice invoice
      receipt.receipt_nr = 1
      receipt.invoice_id = 'tx_1'
      receipt.save.should be_true

      receipt_2 = described_class.new
      receipt_2.update_from_billing_address ba
      receipt_2.update_from_invoice invoice
      receipt_2.receipt_nr = 2
      receipt_2.invoice_id = 'tx_2'
      receipt_2.save.should be_true
    end

  end

  describe "update_from_billing_address" do

    it "updates from billing address" do
      ba = BillingAddressFactory.create_new
      invoice = StripeInvoiceFactory.create_new

      receipt = described_class.new

      receipt.name.should be_nil
      receipt.street.should be_nil
      receipt.zip.should be_nil
      receipt.city.should be_nil
      receipt.company.should be_nil
      receipt.taxid.should be_nil

      receipt.update_from_billing_address ba
      receipt.update_from_invoice invoice

      receipt.name.should eq('Hans Meier')
      receipt.street.should eq('Hansestrasse 112')
      receipt.zip.should eq('12345')
      receipt.city.should eq('Hamburg')
      receipt.country.should eq('DE')
      receipt.company.should eq('HanseComp')
      receipt.taxid.should eq('DE12345')
    end

  end

  describe 'tax_free' do
    it 'is false for DE' do
      receipt = described_class.new({:country => 'DE'})
      receipt.tax_free.should be_false
    end
    it 'is false for FR' do
      receipt = described_class.new({:country => 'FR'})
      receipt.tax_free.should be_false
    end
    it 'is false for FR' do
      receipt = described_class.new({:country => 'GB'})
      receipt.tax_free.should be_false
    end
    it 'is true for US' do
      receipt = described_class.new({:country => 'US'})
      receipt.tax_free.should be_true
    end
  end

  describe 'taxable' do
    it 'is true for DE' do
      receipt = described_class.new({:country => 'DE', :type => Receipt::A_TYPE_INDIVIDUAL})
      receipt.taxable.should be_true
      receipt = described_class.new({:country => 'DE', :type => Receipt::A_TYPE_CORPORATE})
      receipt.taxable.should be_true
    end
    it 'is true for individual in FR' do
      receipt = described_class.new({:country => 'FR', :type => Receipt::A_TYPE_INDIVIDUAL})
      receipt.taxable.should be_true
    end
    it 'is false for companies in FR' do
      receipt = described_class.new({:country => 'FR', :type => Receipt::A_TYPE_CORPORATE})
      receipt.taxable.should be_false
    end
    it 'is false for US' do
      receipt = described_class.new({:country => 'US'})
      receipt.taxable.should be_false
    end
  end

  describe 'reverse_charge' do
    it 'is false for DE' do
      receipt = described_class.new({:country => 'DE', :type => Receipt::A_TYPE_INDIVIDUAL})
      receipt.reverse_charge.should be_false
      receipt = described_class.new({:country => 'DE', :type => Receipt::A_TYPE_CORPORATE})
      receipt.reverse_charge.should be_false
    end
    it 'is true for individual in FR' do
      receipt = described_class.new({:country => 'FR', :type => Receipt::A_TYPE_INDIVIDUAL})
      receipt.reverse_charge.should be_false
    end
    it 'is false for companies in FR' do
      receipt = described_class.new({:country => 'FR', :type => Receipt::A_TYPE_CORPORATE})
      receipt.reverse_charge.should be_true
    end
    it 'is false for US' do
      receipt = described_class.new({:country => 'US'})
      receipt.reverse_charge.should be_false
    end
  end

  describe 'get_binding' do
    it 'returns not nil' do
      receipt = described_class.new({:country => 'US'})
      receipt.get_binding.should_not be_nil
    end
  end

end
