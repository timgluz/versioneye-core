class ReceiptLine < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  require 'versioneye/models/helpers/billing_types'
  include VersionEye::BillingTypes

  require 'versioneye/models/helpers/countries'
  include VersionEye::Countries

  # Billing Address.
  field :type   , type: String, default: 'invoiceitem'

  field :amount        , type: String
  field :currency      , type: String
  field :description   , type: String

  field :period_start  , type: Time
  field :period_end    , type: Time

  field :plan_id       , type: String # Can be empty
  field :plan_name     , type: String # Can be empty

  embedded_in :receipt

  validates_presence_of :type   , :message => 'is mandatory!'

  validates_presence_of :amount      , :message => 'is mandatory!'
  validates_presence_of :currency    , :message => 'is mandatory!'
  validates_presence_of :description , :message => 'is mandatory!'

  validates_presence_of :period_start, :message => 'is mandatory!'
  validates_presence_of :period_end  , :message => 'is mandatory!'


  def update_from json_line
    self.type = json_line[:type]
    self.amount = json_line[:amount]
    self.currency = json_line[:currency]
    self.description = json_line[:description]
    self.period_start = Time.at json_line[:period][:start]
    self.period_end   = Time.at json_line[:period][:end]
    if !json_line[:plan].to_s.empty?
      self.plan_id = json_line[:plan][:id]
      self.plan_name = json_line[:plan][:name]
      self.description = self.plan_name if self.description.to_s.empty?
    end
  end

  # Expose private binding() method.
  def get_binding
    binding()
  end

end
