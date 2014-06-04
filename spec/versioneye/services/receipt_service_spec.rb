require 'spec_helper'

describe ReceiptService do

  before(:each) do
    Plan.create_defaults
  end

  describe "process_receipts" do

    it "returns nil because db is empty" do
      customer = described_class.process_receipts
    end

    it 'iterates' do
      token = fetch_token
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

  def fetch_token
    Stripe::Token.create(
        :card => {
          :number => "4242424242424242",
          :exp_month => 6,
          :exp_year => 2015,
          :cvc => "314"
        },
      )
  end

end
