class Receipt < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  # Billing Address.
  field :type   , type: String, :default => BillingAddress::A_TYPE_INDIVIDUAL
  field :name   , type: String
  field :street , type: String
  field :zip    , type: String
  field :city   , type: String
  field :country, type: String
  field :company, type: String
  field :taxid  , type: String

  # This fields filled from Stripe invoice object.
  field :invoice_id    , type: String
  field :invoice_date  , type: String
  field :period_start  , type: String
  field :period_end    , type: String
  field :plan_name_id  , type: String
  field :amount        , type: String
  field :paid          , type: Boolean
  field :closed        , type: Boolean

  # Rechnungsnummer, fortlaufend! Wichtig fuer das Finanzamt!
  field :receipt_nr  , type: Integer

  belongs_to :user
  belongs_to :plan

  validates_presence_of :type   , :message => 'is mandatory!'
  validates_presence_of :name   , :message => 'is mandatory!'
  validates_presence_of :street , :message => 'is mandatory!'
  validates_presence_of :zip    , :message => 'is mandatory!'
  validates_presence_of :city   , :message => 'is mandatory!'
  validates_presence_of :country, :message => 'is mandatory!'

  validates :receipt_nr, presence: true,
                         length: {minimum: 1, maximum: 250},
                         uniqueness: true

  validates :invoice_id, presence: true,
                         length: {minimum: 1, maximum: 250},
                         uniqueness: true

  def update_from_billing_address ba
    self.type = ba.type
    self.name = ba.name
    self.street = ba.street
    self.zip = ba.zip
    self.city = ba.city
    self.country = ba.country
    self.company = ba.company
    self.taxid = ba.taxid
  end

end
