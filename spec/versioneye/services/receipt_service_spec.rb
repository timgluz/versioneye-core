require 'spec_helper'

describe ReceiptService do

  before(:each) do
    Plan.create_defaults
  end

  describe "process_receipts" do

    it "executes without errors" do
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
