require 'spec_helper'

describe ReceiptService do

  before(:each) do
    Plan.create_defaults
    AWS.config(:s3_endpoint => 'localhost', :s3_port => 4567, :use_ssl => false )
  end

  describe "process_receipts" do

    it "returns nil because db is empty" do
      customer = described_class.process_receipts
    end

    it 'iterates' do
      token = StripeFactory.token
      token_id = token[:id]
      personal_plan = Plan.personal_plan_6
      email = 'hans@wur.st'
      customer = StripeService.create_customer token_id, personal_plan.name_id, email

      user = UserFactory.create_new 1
      user.plan = Plan.personal_plan_6
      user.billing_address = BillingAddressFactory.create_new
      user.stripe_customer_id = customer.id
      user.stripe_token = token_id
      user.save

      Receipt.count.should == 0
      described_class.process_receipts
      Receipt.count.should == 1
      rec = Receipt.first
      rec.plan_id = Plan.personal_plan_6.name_id
      rec.amount.should eq('600')
      rec.currency.should eq('eur')
    end

  end

  describe 'compile_html_invoice' do
    it 'compiles' do
      user = UserFactory.create_new
      receipt = ReceiptFactory.create_new
      receipt.user = user
      described_class.compile_html_invoice receipt
    end
  end

  describe 'next_receipt_nr' do
    it 'returns 1001' do
      described_class.next_receipt_nr.should == 1001
    end
    it 'returns 1002' do
      nr = described_class.next_receipt_nr
      ba = BillingAddressFactory.create_new
      invoice = StripeInvoiceFactory.create_new
      receipt = Receipt.new
      receipt.update_from_billing_address ba
      receipt.update_from_invoice invoice
      receipt.invoice_id = 'tx_1'
      receipt.receipt_nr = nr
      receipt.save.should be_true
      nr = described_class.next_receipt_nr
      nr.should == 1002
    end
  end

end
