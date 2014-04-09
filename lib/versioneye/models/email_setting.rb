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

  validates_presence_of :address , :message => 'Address is mandatory!'
  validates_presence_of :port    , :message => 'Port is mandatory!'
  validates_presence_of :username, :message => 'Username is mandatory!'
  validates_presence_of :password, :message => 'Password is mandatory!'
  validates_presence_of :domain  , :message => 'Domain is mandatory!'
  validates_presence_of :authentification, :message => 'Authentification is mandatory!'
  validates_presence_of :enable_starttls_auto, :message => 'Enable_starttls_auto is mandatory!'

end
