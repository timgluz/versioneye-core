class Team < Versioneye::Model

  # Non Profit Domains

  include Mongoid::Document
  include Mongoid::Timestamps

  field :name       , type: String

  has_many :team_members
  has_and_belongs_to_many :projects

  validates_presence_of   :name, :message => 'is mandatory!'
  # validates_uniqueness_of :name, :message => 'exist already.'

  scope :by_owner, ->(user) { where(owner_id: user.ids) }

  def add_member user
    return false if user.nil?
    self.team_members.each do |member|
      return false if member.user.ids.eql?(user.ids)
    end
    tm = TeamMember.new({:user => user, :team => self})
    tm.save
  end

  def remove_member user
    return false if user.nil?
    self.team_members.each do |member|
      if member.user.ids.eql?(user.ids)
        member.delete
        return true
      end
    end
    false
  end

end
