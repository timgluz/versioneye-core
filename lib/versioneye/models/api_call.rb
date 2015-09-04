class ApiCall < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  field :api_key    , type: String
  field :user_id    , type: String
  field :fullpath   , type: String
  field :http_method, type: String
  field :ip         , type: String

  index({ api_key: 1 }, { name: "api_key_index", background: true })
  index({ user_id: 1 }, { name: "user_id_index", background: true })

  validates :fullpath, presence: true

  scope :by_user,    ->(user)   { where(user_id: user.id.to_s) }
  scope :by_api_key, ->(api_key){ where(api_key: api_key) }
  scope :today,      ->{ where(:created_at.gte => Date.today.midnight, :created_at.lt => Date.tomorrow.midnight) }

  def user
    User.find user_id
  end

end
