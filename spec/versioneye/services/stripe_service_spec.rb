require 'spec_helper'

describe StripeService do

  before(:each) do
    Plan.create_defaults
  end

  describe "create_customer" do

    it "creates a customer" do
      token = StripeFactory.token
      small = Plan.small
      email = 'hans@wur.st'

      customer = described_class.create_customer token[:id], small.name_id, email
      expect( customer ).to_not be_nil
      expect( customer.id ).to_not be_nil
      expect( customer.email ).to eq(email)
    end

    it "does not create a customer" do
      token = 'error_token'
      small = Plan.small
      email = 'hans@wur.st'

      customer = described_class.create_customer token, small.name_id, email
      expect( customer ).to be_nil
    end

  end

  describe 'fetch_customer' do

    it 'fetches the correct customer' do
      token = StripeFactory.token
      small = Plan.small
      email = 'hans@wur.st'
      customer = described_class.create_customer token[:id], small.name_id, email

      id = customer.id
      cust = described_class.fetch_customer id
      expect( cust ).to_not be_nil
      expect( cust.id ).to eq(id)
    end

    it 'returns nil because customer id does not exist' do
      cust = described_class.fetch_customer '88fjaj'
      expect( cust ).to be_nil
    end

  end

  describe 'update_customer' do

    it 'updates the customer' do
      token = StripeFactory.token
      token_id = token[:id]
      small = Plan.small
      email = 'hans@wur.st'
      customer = described_class.create_customer token_id, small.name_id, email
      expect( customer ).to_not be_nil

      orga = Organisation.new({:name => 'test_orga'})
      orga.plan = Plan.micro
      orga.stripe_customer_id = customer.id
      orga.stripe_token = token_id
      expect( orga.save ).to be_truthy

      new_token = StripeFactory.token
      token_id = new_token[:id]
      business_plan = Plan.medium
      cust = described_class.update_customer orga.stripe_customer_id, token_id, business_plan.name_id
      expect( cust ).to_not be_nil
      expect( cust[:subscription][:plan][:id] ).to eq(business_plan.name_id)
    end

  end

  describe 'create_or_update_customer' do

    it 'returns nil because of an error' do
      customer = described_class.create_or_update_customer nil, nil, nil, nil
      expect( customer ).to be_nil
    end

    it 'creates a new customer' do
      orga = Organisation.new({:name => 'test_orga'})
      orga.plan = Plan.micro
      expect( orga.save ).to be_truthy
      expect( orga.stripe_customer_id ).to be_nil
      token = StripeFactory.token
      small = Plan.small.name_id
      customer = described_class.create_or_update_customer orga.stripe_customer_id, token[:id], small, orga.email
      expect( customer ).to_not be_nil
      expect( customer.id ).to_not be_nil
    end

    it 'updates an existing customer' do
      orga = Organisation.new({:name => 'test_orga'})
      orga.plan = Plan.micro
      expect( orga.save ).to be_truthy

      ba = orga.fetch_or_create_billing_address
      ba.name = 'test'
      ba.email = 'test@test.de'
      ba.street = "test"
      ba.zip = '48123'
      ba.city = 'Mannheim'
      ba.country = 'DE'
      expect( ba.save ).to be_truthy

      token = StripeFactory.token
      token_id = token[:id]
      small = Plan.small.name_id

      customer = described_class.create_customer token_id, small, orga.fetch_or_create_billing_address.email
      orga.stripe_customer_id = customer.id
      expect( orga.save ).to be_truthy

      token = StripeFactory.token
      token_id = token[:id]
      business_plan = Plan.medium.name_id
      customer = described_class.create_or_update_customer orga.stripe_customer_id, token_id, business_plan, orga.fetch_or_create_billing_address.email
      expect( customer ).to_not be_nil
      expect( customer.id ).to_not be_nil
    end

  end

  describe 'delete' do

    it 'returns false becasue customer id is nil' do
      expect( described_class.delete(nil) ).to be_falsey
    end

    it 'returns false becasue customer id does not exist' do
      expect( described_class.delete('as_klas88') ).to be_falsey
    end

    it 'returns true' do
      token = StripeFactory.token
      small = Plan.small
      email = 'hans@wur.st'

      customer = described_class.create_customer token[:id], small.name_id, email
      expect( customer ).to_not be_nil

      cust = described_class.fetch_customer customer.id
      expect( cust ).to_not be_nil
      expect( cust[:deleted] ).to be_falsey

      expect( described_class.delete(customer.id) ).to be_truthy

      cust = described_class.fetch_customer customer.id
      expect( cust ).to_not be_nil
      expect( cust[:deleted] ).to be_truthy
    end

  end

  describe 'get_invoice' do

    it 'returns nil because invoice id is wrong' do
      expect( described_class.get_invoice(nil) ).to be_nil
    end
    it 'returns nil because invoice id is wrong' do
      expect( described_class.get_invoice('asgasf') ).to be_nil
    end
    it 'returns the invoice' do
      token = StripeFactory.token
      small = Plan.small
      email = 'hans@wur.st'

      customer = described_class.create_customer token[:id], small.name_id, email
      expect( customer ).to_not be_nil
      invoices = customer.invoices
      expect( invoices ).to_not be_nil
      invoice = invoices.first
      expect( invoice ).to_not be_nil
      inv = described_class.get_invoice(invoice.id)
      expect( inv ).to_not be_nil
      expect( inv.id ).to eq(invoice.id)
    end

  end

end
