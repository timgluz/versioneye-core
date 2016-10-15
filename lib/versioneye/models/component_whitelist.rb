class ComponentWhitelist < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  field :name,             type: String
  field :default,          type: Boolean, default: false
  field :components,       type: Array, default: []

  belongs_to :user, optional: true
  belongs_to :organisation

  validates_presence_of :name, :message => 'is mandatory!'

  scope :by_user, ->(user) { where(user_id: user[:_id].to_s) }
  scope :by_orga, ->(orga) { where(organisation_id: orga.ids) }
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

  def self.fetch_by organisation, name
    self.by_orga(organisation).by_name(name).first
  end

  def add element
    self.components << element.downcase.gsub(" ", "") if !is_on_list?(element)
  end

  def remove element
    self.components.delete element
  end

  def is_on_list? element
    return true if self.components.include?(element.downcase)

    components.each do |component|
      return true if element.downcase.match( /\A#{component}/ )
    end

    false
  end

  def auditlogs
    Auditlog.where(:domain => "ComponentWhitelist", :domain_id => self.id.to_s).desc(:created_at)
  end

end
