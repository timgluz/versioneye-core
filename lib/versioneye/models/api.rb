class Api < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id            , type: String
  field :api_key            , type: String
  field :enterprise_projects, type: Integer, default: 1
  field :rate_limit         , type: Integer, default: 50
  field :active             , type: Boolean, default: true
  field :update_di          , type: Boolean, default: false # Update Docker Images


  index({ api_key: 1 }, { name: "api_key_index", unique: true, drop_dups: true, background: true })

  validates :user_id, presence: true
  validates :api_key, presence: true,
                      length: {minimum: 20, maximum: 20},
                      uniqueness: true

  def self.by_user(user)
    Api.where(user_id: user[:_id].to_s).first
  end

  def self.create_new(user)
    new_api = Api.new(user_id: user[:_id].to_s)
    new_api.generate_api_key!
    new_api.save
    new_api
  end

  def self.generate_api_key(length = 20)
    length = (length / 2.0).round
    length = 1 if length < 1
    SecureRandom.hex(length)
  end

  def generate_api_key!(length =  20)
    self.api_key = Api.generate_api_key(length)
  end

  def user
    User.find user_id
  end

  def calls_count
    ApiCall.where(:api_key => self.api_key).count
  end

end
