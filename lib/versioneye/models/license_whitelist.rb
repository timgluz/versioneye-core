class LicenseWhitelist < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String

  embeds_many :license_elements

  belongs_to :user

  index({user_id: 1, name: 1},  { name: "user_id_name", background: true, unique: true })

  scope :by_user, ->(user) { where(user_id: user[:_id].to_s) }
  scope :by_name, ->(name)  { where(name:  name ) }

  def to_s
    name
  end

  def to_param
    name
  end

  def update_from params
    self.name = params[:name]
  end

  def self.fetch_by user, name
    self.by_user(user).by_name(name).first
  end

  def self.licenses
    License.distinct(:name)
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

end
