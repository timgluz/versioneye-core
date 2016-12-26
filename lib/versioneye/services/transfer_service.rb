class TransferService < Versioneye::Service


  def self.process limit = 10000
    transfers = Stripe::Transfer.all(:limit => limit)
    transfers.each do |tr|
      process_transfer tr
    end
    nil
  end


  def self.process_transfer tr
    currency = tr.currency.upcase
    gross    = tr.summary.charge_gross.to_f / 100
    fees     = tr.summary.charge_fees.to_f / 100
    net      = tr.amount.to_f / 100
    datef    = Time.at(tr.date).strftime("%d.%m.%Y")

    p ""
    p "#{datef} - #{tr.id} - Charged: #{'%.02f' % gross} #{currency} - Fee: #{'%.02f' % fees} #{currency} - Transfered: #{'%.02f' % net} #{currency}"
    tr.transactions.each do |tx|
      process_transaction tx, currency
    end
  end


  def self.process_transaction tx, currency
    charge = Stripe::Charge.retrieve(tx.id)
    receipt_nr = ''
    receipt = Receipt.where(:invoice_id => charge.invoice).first
    if receipt
      receipt_nr = receipt.receipt_nr # Rechnungsnummer
    end
    amount = tx.amount.to_f / 100
    fee = tx.fee.to_f / 100
    net = tx.net.to_f / 100
    p " -> #{tx.customer_details} (#{receipt_nr}) - Charged: #{amount} #{currency} - Fee: #{fee} #{currency} - Net: #{net} #{currency}"
  end


  def self.download_receipts directory = '/Users/reiz/stripe'
    bucket_name = 'veye-prod-receipt'
    s3 = Aws::S3::Client.new
    s3.list_objects(bucket: bucket_name).each do |response|
      response.contents.each do |content|
        obj_key = content.key
        download directory, s3, bucket_name, obj_key
      end
    end
  end


  private


    def self.download directory, s3, bucket_name, obj_key
      filename = "#{directory}/#{obj_key}"
      File.open(filename, 'wb') do |file|
        reap = s3.get_object({ bucket: bucket_name, key: obj_key }, target: file)
      end
      p "downloaded file to #{filename}"
    end


end
