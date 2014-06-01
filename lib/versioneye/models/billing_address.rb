class BillingAddress < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  require 'versioneye/models/helpers/countries'
  include VersionEye::Countries

  A_TYPE_INDIVIDUAL = 'Individual'
  A_TYPE_COROPORATE = 'Corporation'

  field :type   , type: String, :default => A_TYPE_INDIVIDUAL
  field :name   , type: String
  field :street , type: String
  field :zip    , type: String
  field :city   , type: String
  field :country, type: String
  field :company, type: String
  field :taxid  , type: String

  validates_presence_of :type   , :message => 'is mandatory!'
  validates_presence_of :name   , :message => 'is mandatory!'
  validates_presence_of :street , :message => 'is mandatory!'
  validates_presence_of :zip    , :message => 'is mandatory!'
  validates_presence_of :city   , :message => 'is mandatory!'
  validates_presence_of :country, :message => 'is mandatory!'

  belongs_to :user

  before_save :validate_type, :validate_country

  def update_from_params( params )
    self.type    = params[:type] if !params[:type].to_s.empty?
    self.name    = params[:name]
    self.street  = params[:street]
    self.zip     = params[:zip_code]
    self.city    = params[:city]
    self.country = params[:country]
    self.company = params[:company]
    self.taxid   = params[:taxid]
    self.save
  end

  private

    # For corporations the company name is mandatory
    def validate_type
      if self.type.eql?(A_TYPE_COROPORATE) && self.company.to_s.empty?
        self.errors.messages[:company] = ["is mandatory"]
        return false
      end
      true
    end

    def validate_country
      if !A_COUNTRIES.keys.include?(self.country)
        self.errors.messages[:country] = ["is not valid value"]
        return false
      end
      true
    end

end
