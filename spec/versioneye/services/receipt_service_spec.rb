require 'spec_helper'

describe ReceiptService do

  before(:each) do
    Plan.create_defaults
  end

  describe 'next_receipt_nr' do
    it 'returns 1001' do
      described_class.next_receipt_nr.should == 1001
    end
    it 'returns 1002' do
      nr = described_class.next_receipt_nr
      ba = BillingAddressFactory.create_new
      receipt = Receipt.new
      receipt.update_from_billing_address ba
      receipt.invoice_id = 'tx_1'
      receipt.receipt_nr = nr
      receipt.save.should be_true
      nr = described_class.next_receipt_nr
      nr.should == 1002
    end
  end

  describe "process_receipts" do

    it "returns nil because db is empty" do
      customer = described_class.process_receipts
    end

    it 'iterates' do
      token = StripeFactory.token
      token_id = token[:id]
      personal_plan = Plan.personal_plan
      email = 'hans@wur.st'
      customer = StripeService.create_customer token_id, personal_plan.name_id, email

      user = UserFactory.create_new 1
      user.stripe_customer_id = customer.id
      user.stripe_token = token_id
      user.save

      customer = described_class.process_receipts
    end

  end

end
