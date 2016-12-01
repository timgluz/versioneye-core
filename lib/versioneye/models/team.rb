class Team < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  A_OWNERS = 'Owners'

  field :name, type: String

  field :version_notifications,  type: Boolean, default: true
  field :license_notifications,  type: Boolean, default: true
  field :security_notifications, type: Boolean, default: true

  has_many :members, class_name: 'TeamMember'

  belongs_to :organisation

  validates_presence_of   :name, :message => 'is mandatory!'
  validates_presence_of   :organisation, :message => 'is mandatory!'

  scope :by_organisation, ->(organisation) { where(organisation_id: organisation.ids).asc(:name) }

  def to_s
    name
  end

  def to_param
    name
  end

  def add_member user
    return false if user.nil?
    self.members.each do |member|
      return false if member.user.ids.eql?(user.ids)
    end
    tm = TeamMember.new({:user => user, :team => self})
    tm.save
  end

  def remove_member user
    return false if user.nil?
    self.members.each do |member|
      if member.user.ids.eql?(user.ids)
        member.delete
        return true
      end
    end
    false
  end

  def is_member? user
    return false if user.nil?
    self.members.each do |member|
      return true if member.user.ids.eql?(user.ids)
    end
    false
  end

end
