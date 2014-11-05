class EmailSetting < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  field :address             , type: String , default: 'your.smtp.server.com'
  field :port                , type: Integer, default: 587
  field :username            , type: String , default: 'username'
  field :password            , type: String , default: 'password'
  field :domain              , type: String , default: 'your.domain.com'
  field :authentication      , type: String , default: 'plain'
  field :enable_starttls_auto, type: Boolean, default: true
  field :sender_name         , type: String , default: 'VersionEye'
  field :sender_email        , type: String , default: 'notify@versioneye.com'

  validates_presence_of :address , :message => 'is mandatory!'
  validates_presence_of :port    , :message => 'is mandatory!'
  validates_presence_of :enable_starttls_auto, :message => 'is mandatory!'
  validates_presence_of :sender_email, :message => 'is mandatory!'

  def self.create_default
    email_setting = EmailSetting.new
    email_setting.save
    email_setting
  end

  def update_from params
    self.address              = params[:address]
    self.port                 = params[:port]
    self.username             = params[:username]
    self.password             = params[:password] if params[:password]
    self.domain               = params[:domain]
    self.authentication       = params[:authentication]
    tls = false
    if params[:enable_starttls_auto] && params[:enable_starttls_auto].eql?("true")
      tls = true
    end
    self.enable_starttls_auto = tls
    self.sender_name          = params[:sender_name] if params[:sender_name]
    self.sender_email         = params[:sender_email] if params[:sender_email]
    self.save
  rescue => e
    log.error e.message
    false
  end

end
