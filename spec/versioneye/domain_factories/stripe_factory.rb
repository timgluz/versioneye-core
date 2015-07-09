class StripeFactory

  def self.token
    Stripe::Token.create(
        :card => {
          :number => "4242424242424242",
          :exp_month => 6,
          :exp_year => 2019,
          :cvc => "314"
        },
      )
  end

end
