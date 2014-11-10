class Auditlog < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id    , type: String
  field :domain     , type: String
  field :domain_id  , type: String
  field :action     , type: String

  index({ user_id: 1 }, { name: "user_id_index", background: true })

  validates :user_id  , presence: true
  validates :domain   , presence: true
  validates :domain_id, presence: true
  validates :action   , presence: true

  scope :by_user,    ->(user)   { where(user_id: user.id.to_s) }
  scope :today,      ->{ where(:created_at.gte => Date.today.midnight, :created_at.lt => Date.tomorrow.midnight) }


  def self.add user, domain, id, action
    Auditlog.new({:user_id => user.id.to_s, :domain => domain, :domain_id => id, :action => action }).save
  end

  def user
    User.find user_id
  end

end
