class BillingAddress < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  require 'versioneye/models/helpers/countries'
  include VersionEye::Countries

  require 'versioneye/models/helpers/billing_types'
  include VersionEye::BillingTypes

  field :type   , type: String, :default => A_TYPE_INDIVIDUAL
  field :name   , type: String
  field :street , type: String
  field :zip    , type: String
  field :city   , type: String
  field :country, type: String
  field :company, type: String
  field :taxid  , type: String
  field :email  , type: String

  validates_presence_of :type   , :message => 'is mandatory!'
  validates_presence_of :name   , :message => 'is mandatory!'
  validates_presence_of :street , :message => 'is mandatory!'
  validates_presence_of :zip    , :message => 'is mandatory!'
  validates_presence_of :city   , :message => 'is mandatory!'
  validates_presence_of :country, :message => 'is mandatory!'
  validates_presence_of :email  , :message => 'is mandatory!'

  belongs_to :organisation

  index({ user_id: 1 }, { name: "user_id_index", background: true })

  before_save :validate_country, :validate_company, :validate_taxid

  def update_from_params( params )
    self.type    = params[:type] if !params[:type].to_s.empty?
    self.name    = params[:name]
    self.street  = params[:street]
    self.zip     = params[:zip_code]
    self.city    = params[:city]
    self.country = params[:country]
    self.company = params[:company]
    self.taxid   = params[:taxid]
    self.email   = params[:email]
    self.save
  end

  def taxid_mandatory?
    return true if type.eql?(A_TYPE_CORPORATE) && A_EU.keys.include?(country)
    return false
  end

  def company_mandatory?
    return true if type.eql?(A_TYPE_CORPORATE)
    return false
  end

  private

    # For corporations the company name is mandatory
    def validate_company
      if company_mandatory? && company.to_s.empty?
        self.errors.messages[:company] = ["is mandatory"]
        return false
      end
      true
    end

    # For corporations in the EU the taxid is mandatory
    def validate_taxid
      if taxid_mandatory? && taxid.to_s.empty?
        self.errors.messages[:taxid] = ["is mandatory"]
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
