class ReceiptFactory

  def self.create_new n, persist = false
    nr = ReceiptService.next_receipt_nr
    ba = BillingAddressFactory.create_new
    invoice = StripeInvoiceFactory.create_new
    receipt = Receipt.new
    receipt.update_from_billing_address ba
    receipt.update_from_invoice invoice
    receipt.invoice_id = "tx_#{n}"
    receipt.receipt_nr = nr
    receipt.save if persist
    receipt
  end

end
