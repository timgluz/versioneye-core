class ReceiptService < Versioneye::Service


  require 'pdfkit'


  def self.process_receipts
    return nil if Settings.instance.environment.eql?("enterprise")

    count = Organisation.where(:plan_id.ne => nil).count
    return nil if count == 0

    per_page = 30
    skip = 0
    iterations = count / per_page
    iterations += 1

    (0..iterations).each do
      orgas = Organisation.where(:plan_id.ne => nil).skip(skip).limit(per_page)
      handle_orgas( orgas )
      skip += per_page
    end
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end


  def self.handle_orgas( orgas )
    return nil if orgas.nil? || orgas.empty?

    orgas.each do |orga|
      next if orga.nil?
      next if orga.plan.name_id.eql?(Plan::A_PLAN_FREE)
      next if orga.plan.name_id.eql?('01_free')
      next if orga.plan.name_id.eql?('02_free')
      next if orga.plan.name_id.eql?('03_free')
      next if orga.plan.name_id.eql?('03_trial_0')
      next if orga.plan.name_id.eql?('04_free')
      next if orga.plan.name.match(/Free\Z/i)
      next if orga.stripe_token.to_s.empty?
      next if orga.stripe_customer_id.to_s.empty?

      handle_orga( orga )
    end
  end


  def self.handle_orga( orga, send_email = true )
    customer = StripeService.fetch_customer orga.stripe_customer_id
    return nil if customer.nil?

    invoices = customer.invoices
    return nil if invoices.nil? || invoices.count == 0

    invoices.each do |invoice|
      handle_invoice orga, invoice, send_email
    end
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end


  def self.handle_invoice orga, invoice, send_email = true
    receipt = Receipt.where(:invoice_id => invoice[:id]).shift
    return receipt if receipt # Early exit if receipt exist already in db

    receipt = new_receipt orga, invoice

    html    = compile_html_invoice receipt
    pdf     = compile_pdf_invoice html
    upload( receipt, pdf )
    if receipt.save && orga.plan && orga.plan.name_id.to_s.match(/\A04/)
      email( receipt, pdf ) if send_email == true
    else
      log.error "Could not persist receipt for orga '#{orga.id}' and invoice '#{invoice[:id]}' - #{receipt.errors.full_messages}"
    end

    receipt
  rescue => e
    log.error "ERROR for orga #{orga.name} - #{e.message}"
    log.error e.backtrace.join("\n")
  end


  def self.new_receipt orga, invoice
    receipt = Receipt.new
    receipt.update_from_billing_address orga.billing_address
    receipt.update_from_invoice invoice
    receipt.receipt_nr   = next_receipt_nr
    receipt.organisation = orga
    receipt.plan         = orga.plan
    receipt
  end


  def self.next_receipt_nr
    nr = Receipt.max(:receipt_nr)
    nr = 1000 if nr.nil?
    nr += 1
    nr
  end


  def self.compile_html_invoice receipt, compile_pdf = false
    content_file = Settings.instance.receipt_content
    erb = ERB.new(File.read(content_file))
    html = erb.result(receipt.get_binding)
    html = html.force_encoding(Encoding::UTF_8)

    if compile_pdf
      compile_pdf_invoice html, receipt
    end

    html
  end


  # Note for me.. kit.to_file('/Users/robertreiz/invoice.pdf')
  def self.compile_pdf_invoice html, receipt = nil
    footer_file = Settings.instance.receipt_footer
    kit = PDFKit.new(html, :footer_html => footer_file, :page_size => 'A4')

    raise "PDFKit.new returned nil!" if kit.nil?

    if receipt
      kit.to_file("#{ENV['HOME']}/#{receipt.filename}")
    end

    kit.to_pdf
  end


  def self.upload receipt, pdf
    S3.store_in_receipt_bucket receipt.filename, pdf
  end


  def self.email receipt, pdf
    ReceiptMailer.receipt_email(receipt, pdf).deliver_now
  end


end
