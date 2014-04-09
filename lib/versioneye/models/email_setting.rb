class EmailSetting < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  field :address             , type: String , default: 'email-smtp.eu-west-1.amazonaws.com'
  field :port                , type: Integer, default: 587
  field :username            , type: String , default: 'username'
  field :password            , type: String , default: 'password'
  field :domain              , type: String , default: 'versioneye.com'
  field :authentication      , type: String , default: 'plain'
  field :enable_starttls_auto, type: Boolean, default: true

  validates_presence_of :address , :message => 'is mandatory!'
  validates_presence_of :port    , :message => 'is mandatory!'
  validates_presence_of :username, :message => 'is mandatory!'
  validates_presence_of :password, :message => 'is mandatory!'
  validates_presence_of :domain  , :message => 'is mandatory!'
  validates_presence_of :authentication, :message => 'is mandatory!'
  validates_presence_of :enable_starttls_auto, :message => 'is mandatory!'

  def self.create_default
    EmailSetting.new.save
  end

end
