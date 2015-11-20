class Team < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String

  has_many :members, class_name: 'TeamMember'

  belongs_to :organisation

  validates_presence_of   :name, :message => 'is mandatory!'

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

end
