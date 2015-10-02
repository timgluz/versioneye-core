class StripeInvoiceFactory

  def self.create_new(n = 1)
    invoice = Stripe::Invoice.new({:id => "inv_#{n}"})
    invoice[:date]         = 1349738955
    invoice[:period_start] = 1349738951
    invoice[:period_end]   = 1349738952
    invoice[:amount]       = '600'
    invoice[:total]        = '600'
    invoice[:currency]     = 'eur'
    invoice[:paid]         = true
    invoice[:closed]       = true
    invoice[:lines]        = [{
      :type => 'invoiceitem',
      :amount => '600',
      :currency => 'eur',
      :description => 'this is a test',
      :period => {:start => 1349738951, :end => 1349738953},
      :plan => {:id => Plan::A_PLAN_MICRO, :name => 'Personal / Normal'}
    }]
    invoice
  end

  def self.create_defaults(n = 5)
    invoices = []
    1..n.times {|i| invoices << StripeInvoiceFactory.create_new(i)}
    invoices
  end

end
