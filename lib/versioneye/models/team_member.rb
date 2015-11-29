class TeamMember < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :team
  belongs_to :user

  validates_presence_of :user, :message => 'is mandatory!'
  validates_presence_of :team, :message => 'is mandatory!'

end
