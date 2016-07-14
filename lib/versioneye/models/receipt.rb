class Receipt < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  require 'versioneye/models/helpers/billing_types'
  include VersionEye::BillingTypes

  require 'versioneye/models/helpers/countries'
  include VersionEye::Countries

  # Billing Address.
  field :type   , type: String, :default => BillingAddress::A_TYPE_INDIVIDUAL
  field :name   , type: String
  field :street , type: String
  field :zip    , type: String
  field :city   , type: String
  field :country, type: String
  field :company, type: String
  field :taxid  , type: String
  field :email  , type: String

  # Rechnungsnummer, fortlaufend! Wichtig fuer das Finanzamt!
  field :receipt_nr  , type: Integer

  # This fields filled from Stripe invoice object.
  field :total         , type: String
  field :currency      , type: String
  field :paid          , type: Boolean
  field :closed        , type: Boolean

  field :invoice_id    , type: String
  field :invoice_date  , type: Time

  field :period_start  , type: Time
  field :period_end    , type: Time

  embeds_many :receipt_lines

  belongs_to :user
  belongs_to :organisation
  belongs_to :plan

  validates_presence_of :type   , :message => 'is mandatory!'
  validates_presence_of :name   , :message => 'is mandatory!'
  validates_presence_of :street , :message => 'is mandatory!'
  validates_presence_of :zip    , :message => 'is mandatory!'
  validates_presence_of :city   , :message => 'is mandatory!'
  validates_presence_of :country, :message => 'is mandatory!'

  validates_presence_of :invoice_date, :message => 'is mandatory!'
  validates_presence_of :period_start, :message => 'is mandatory!'
  validates_presence_of :period_end  , :message => 'is mandatory!'
  validates_presence_of :total       , :message => 'is mandatory!'
  validates_presence_of :currency    , :message => 'is mandatory!'
  validates_presence_of :paid        , :message => 'is mandatory!'
  validates_presence_of :closed      , :message => 'is mandatory!'


  validates :receipt_nr, presence: true,
                         length: {minimum: 1, maximum: 250},
                         uniqueness: true

  validates :invoice_id, presence: true,
                         length: {minimum: 1, maximum: 250},
                         uniqueness: true

  before_save :pre_process

  def self.by_invoice id
    Receipt.where(:invoice_id => id).first
  end

  def self.by_user id
    Receipt.where(:user_id => id).desc(:invoice_date)
  end

  def pre_process
    return false if company_mandatory? && company.to_s.empty?
    return false if taxid_mandatory? && taxid.to_s.empty?
    true
  end

  def update_from_billing_address ba
    self.type    = ba.type
    self.name    = ba.name
    self.street  = ba.street
    self.zip     = ba.zip
    self.city    = ba.city
    self.country = ba.country
    self.company = ba.company
    self.taxid   = ba.taxid
    self.email   = ba.email
  end

  def update_from_invoice invoice
    self.invoice_id   = invoice[:id]
    self.invoice_date = Time.at invoice[:date]
    self.period_start = Time.at invoice[:period_start]
    self.period_end   = Time.at invoice[:period_end]
    self.total        = invoice[:total]
    self.currency     = invoice[:currency]
    self.paid         = invoice[:paid]
    self.closed       = invoice[:closed]

    invoice.lines.each do |line|
      receipt_line = ReceiptLine.new
      receipt_line.update_from line
      receipt_lines << receipt_line
    end
  end

  def taxid_mandatory?
    return true if type.eql?(A_TYPE_CORPORATE) && A_EU.keys.include?(country)
    return false
  end

  def company_mandatory?
    return true if type.eql?(A_TYPE_CORPORATE)
    return false
  end

  def tax_free
    !A_EU.keys.include?(country)
  end

  def taxable
    return true if country.to_s.eql?('DE')
    return true if type.eql?(A_TYPE_INDIVIDUAL) && A_EU.keys.include?(country)
    return false
  end

  def reverse_charge
    return false if country.to_s.eql?('DE')
    return false if !A_EU.keys.include?(country)
    return true if type.eql?(A_TYPE_CORPORATE) && A_EU.keys.include?(country)
    return false
  end

  # Expose private binding() method.
  def get_binding
    binding()
  end

  def filename
    date_str = invoice_date.strftime("%Y-%m-%d")
    "#{date_str}-VersionEye-#{receipt_nr}.pdf"
  end

  def to_s
    filename
  end

end
