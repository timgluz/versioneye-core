class LicenseWhitelist < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  field :name,             type: String
  field :default,          type: Boolean, default: false
  field :pessimistic_mode, type: Boolean, default: false

  embeds_many :license_elements

  belongs_to :user, optional: true
  belongs_to :organisation

  validates_presence_of :name, :message => 'is mandatory!'

  scope :by_user, ->(user) { where(user_id: user[:_id].to_s) }
  scope :by_orga, ->(orga) { where(organisation_id: orga.ids) }
  scope :by_name, ->(name) { where(name:  name ) }

  def to_s
    name
  end

  def to_param
    name
  end

  def update_from params
    self.name = params[:name]
  end

  def self.fetch_by organisation, name
    self.by_orga(organisation).by_name(name).first
  end

  def license_by_name name
    license_elements.each do |license|
      return license if license.to_s.eql?( name )
    end
    nil
  rescue => e
    log.error e
    nil
  end

  def license_elements_empty?
    license_elements.nil? || license_elements.size == 0 ? true : false
  end

  def add_license_element( name )
    unless license_by_name(name)
      license_element = LicenseElement.new(:name => name)
      license_elements.push( license_element )
    end
  end

  def remove_license_element name
    license_elements.each do |license_element|
      if license_element.to_s.eql?( name )
        license_element.remove
        self.save
        return true
      end
    end
    false
  end

  def include_license_substitute? name
    license_elements.each do |license_element|
      return true if license_element.equals_id?( name )
    end
    false
  end

  def auditlogs
    Auditlog.where(:domain => "LicenseWhitelist", :domain_id => self.id.to_s).desc(:created_at)
  end

end
