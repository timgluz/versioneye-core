class BillingAddressFactory

  def self.create_new( persist = false )
    ba = BillingAddress.new({:name => 'Hans Meier',
      :street => 'Hansestrasse 112', :zip => '12345', :email => 'hi@ton.de',
      :city => 'Hamburg', :country => 'DE', :company => 'HanseComp',
      :taxid => 'DE12345'})
    ba.save if persist
    ba
  end

end
