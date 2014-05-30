class StripeService < Versioneye::Service


  def self.fetch_customer customer_id
    Stripe::Customer.retrieve customer_id
  end


  def self.create_customer stripe_token, plan_name_id, email
    Stripe::Customer.create(
        :card => stripe_token,
        :plan => plan_name_id,
        :email => email
      )
  end


  def self.update_customer user, stripe_token, plan_name_id
    customer = self.fetch_customer user.stripe_customer_id
    customer.card = stripe_token
    customer.save
    customer.update_subscription( :plan => plan_name_id )
    customer
  end


  def self.create_or_update_customer user, stripe_token, plan_name_id
    if user.stripe_customer_id
      return self.update_customer user, stripe_token, plan_name_id
    end
    self.create_customer stripe_token, plan_name_id, user.email
  rescue => e
    log.error e.message
    log.error e.backtrace.join('\n')
    nil
  end


  def self.get_invoice invoice_id
    Stripe::Invoice.retrieve invoice_id
  end


  def self.delete customer_id
    return nil if customer_id.to_s.empty?
    customer = self.fetch_customer customer_id
    customer.delete
  rescue => e
    log.error e.message
    log.error e.backtrace.join('\n')
  end

end
