class TeamMember < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :team
  belongs_to :user

  field :owner        , type: Boolean, default: false # for billing
  field :user_admin   , type: Boolean, default: false # can add/remove users from team
  field :project_admin, type: Boolean, default: false # can add/remove projects from team

  validates_presence_of :user, :message => 'is mandatory!'
  validates_presence_of :team, :message => 'is mandatory!'

end
