require 'spec_helper'

describe StripeService do

  before(:each) do
    Plan.create_defaults
  end

  describe "create_customer" do

    it "creates a customer" do
      token = fetch_token
      personal_plan = Plan.personal_plan
      email = 'hans@wur.st'

      customer = described_class.create_customer token[:id], personal_plan.name_id, email
      customer.should_not be_nil
      customer.id.should_not be_nil
      customer.email.should eq(email)
    end

    it "does not create a customer" do
      token = 'error_token'
      personal_plan = Plan.personal_plan
      email = 'hans@wur.st'

      customer = described_class.create_customer token, personal_plan.name_id, email
      customer.should be_nil
    end

  end

  describe 'fetch_customer' do

    it 'fetches the correct customer' do
      token = fetch_token
      personal_plan = Plan.personal_plan
      email = 'hans@wur.st'
      customer = described_class.create_customer token[:id], personal_plan.name_id, email

      id = customer.id
      cust = described_class.fetch_customer id
      cust.should_not be_nil
      cust.id.should eq(id)
    end

    it 'returns nil because customer id does not exist' do
      cust = described_class.fetch_customer '88fjaj'
      cust.should be_nil
    end

    it 'fetches an legacy customer' do
      customer_id = "cus_46xjeG6vago0z0"
      cust = described_class.fetch_customer customer_id, Settings.instance.stripe_legacy_secret_key
      cust.should_not be_nil
    end

  end

  describe 'update_customer' do

    it 'updates the customer' do
      token = fetch_token
      token_id = token[:id]
      personal_plan = Plan.personal_plan
      email = 'hans@wur.st'
      customer = described_class.create_customer token_id, personal_plan.name_id, email
      customer.should_not be_nil

      user = UserFactory.create_new 1
      user.stripe_customer_id = customer.id
      user.stripe_token = token_id
      user.save.should be_true

      new_token = fetch_token
      token_id = new_token[:id]
      business_plan = Plan.business_small_plan
      cust = described_class.update_customer user, token_id, business_plan.name_id
      cust.should_not be_nil
      cust[:subscription][:plan][:id].should eq(business_plan.name_id)
    end

  end

  describe 'create_or_update_customer' do

    it 'returns nil because of an error' do
      customer = described_class.create_or_update_customer nil, nil, nil
      customer.should be_nil
    end

    it 'creates a new customer' do
      user = UserFactory.create_new 1
      user.stripe_customer_id.should be_nil
      token = fetch_token
      token_id = token[:id]
      personal_plan = Plan.personal_plan.name_id
      customer = described_class.create_or_update_customer user, token_id, personal_plan
      customer.should_not be_nil
      customer.id.should_not be_nil
    end

    it 'updates an existing customer' do
      user = UserFactory.create_new 1
      token = fetch_token
      token_id = token[:id]
      personal_plan = Plan.personal_plan.name_id

      customer = described_class.create_customer token_id, personal_plan, user.email
      user.stripe_customer_id = customer.id
      user.save.should be_true

      token = fetch_token
      token_id = token[:id]
      business_plan = Plan.business_small_plan.name_id
      customer = described_class.create_or_update_customer user, token_id, business_plan
      customer.should_not be_nil
      customer.id.should_not be_nil
    end

  end

  describe 'delete' do

    it 'returns false becasue customer id is nil' do
      described_class.delete(nil).should be_false
    end

    it 'returns false becasue customer id does not exist' do
      described_class.delete('as_klas88').should be_false
    end

    it 'returns true' do
      token = fetch_token
      personal_plan = Plan.personal_plan
      email = 'hans@wur.st'

      customer = described_class.create_customer token[:id], personal_plan.name_id, email
      customer.should_not be_nil

      cust = described_class.fetch_customer customer.id
      cust.should_not be_nil
      cust[:deleted].should be_false

      described_class.delete(customer.id).should be_true

      cust = described_class.fetch_customer customer.id
      cust.should_not be_nil
      cust[:deleted].should be_true
    end

  end

  describe 'get_invoice' do

    it 'returns nil because invoice id is wrong' do
      described_class.get_invoice(nil).should be_nil
    end
    it 'returns nil because invoice id is wrong' do
      described_class.get_invoice('asgasf').should be_nil
    end
    it 'returns the invoice' do
      token = fetch_token
      personal_plan = Plan.personal_plan
      email = 'hans@wur.st'

      customer = described_class.create_customer token[:id], personal_plan.name_id, email
      customer.should_not be_nil
      invoices = customer.invoices
      invoices.should_not be_nil
      invoice = invoices.first
      invoice.should_not be_nil
      inv = described_class.get_invoice(invoice.id)
      inv.should_not be_nil
      inv.id.should eq(invoice.id)
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
