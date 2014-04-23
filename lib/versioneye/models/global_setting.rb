class GlobalSetting < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  field :server_url , type: String , default: 'http://localhost:3000'
  field :server_host, type: String , default: 'localhost'
  field :server_port, type: Integer, default: 3000

  field :github_api_url      , type: String , default: 'https://api.github.com'
  field :github_client_id    , type: String , default: 'client_id'
  field :github_client_secret, type: String , default: 'client_secret'

  validates_presence_of :server_url , :message => 'is mandatory!'
  validates_presence_of :server_host, :message => 'is mandatory!'
  validates_presence_of :server_port, :message => 'is mandatory!'

  def self.default
    gs = GlobalSetting.first
    if gs.nil?
      gs = GlobalSetting.new
      gs.save
    end
    gs
  end

end
