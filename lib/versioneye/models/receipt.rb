class Receipt < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  field :type   , type: String, :default => BillingAddress::A_TYPE_INDIVIDUAL
  field :name   , type: String
  field :street , type: String
  field :zip    , type: String
  field :city   , type: String
  field :country, type: String
  field :company, type: String
  field :taxid  , type: String

  field :period_start  , type: String
  field :period_end    , type: String
  field :plan_name_id  , type: String
  field :amount        , type: String
  field :transaction_id, type: String

  field :receipt_nr  , type: Integer

  belongs_to :user
  belongs_to :plan

  validates_presence_of :type   , :message => 'is mandatory!'
  validates_presence_of :name   , :message => 'is mandatory!'
  validates_presence_of :street , :message => 'is mandatory!'
  validates_presence_of :zip    , :message => 'is mandatory!'
  validates_presence_of :city   , :message => 'is mandatory!'
  validates_presence_of :country, :message => 'is mandatory!'

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
