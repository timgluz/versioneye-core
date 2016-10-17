class BillingAddressFactory

  def self.create_new( persist = false, orga = nil )
    ba = BillingAddress.new({:name => 'Hans Meier',
      :street => 'Hansestrasse 112', :zip => '12345', :email => 'hi@ton.de',
      :city => 'Hamburg', :country => 'DE', :company => 'HanseComp',
      :taxid => 'DE12345'})
    ba.organisation = orga
    ba.save if persist
    ba
  end

end
