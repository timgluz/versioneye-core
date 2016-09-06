class StripeService < Versioneye::Service

  require 'stripe'

  def self.fetch_customer customer_id, api_key = nil
    return Stripe::Customer.retrieve(customer_id, api_key) if !api_key.to_s.empty?
    return Stripe::Customer.retrieve customer_id
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    nil
  end


  def self.create_customer stripe_token, plan_name_id, email
    Stripe::Customer.create(
        :card => stripe_token,
        :plan => plan_name_id,
        :email => email)
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    nil
  end


  def self.update_customer stripe_customer_id, stripe_token, plan_name_id
    customer = self.fetch_customer stripe_customer_id
    customer.card = stripe_token
    customer.save
    customer.update_subscription( :plan => plan_name_id )
    customer
  end


  def self.create_or_update_customer stripe_customer_id, stripe_token, plan_name_id, email
    return nil if stripe_token.to_s.empty?
    return nil if plan_name_id.to_s.empty?

    if stripe_customer_id
      return self.update_customer stripe_customer_id, stripe_token, plan_name_id
    end
    self.create_customer stripe_token, plan_name_id, email
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    nil
  end


  def self.delete customer_id
    return false if customer_id.to_s.empty?

    customer = self.fetch_customer customer_id
    customer.delete
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    false
  end


  def self.get_invoice invoice_id, api_key = nil
    return Stripe::Invoice.retrieve(invoice_id, api_key) if !api_key.to_s.empty?
    return Stripe::Invoice.retrieve invoice_id
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    nil
  end


end
