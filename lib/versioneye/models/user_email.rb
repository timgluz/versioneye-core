class UserEmail < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id     , type: String
  field :email       , type: String
  field :verification, type: String

  index({ email: 1 },        { name: "email_index",        background: true, unique: true })
  index({ user_id: 1 },      { name: "user_id_index",      background: true })
  index({ verification: 1 }, { name: "verification_index", background: true })

  validates_presence_of :email, :message => 'is mandatory!'
  validates_format_of   :email, with: User::A_EMAIL_REGEX


  def user 
    User.find(self.user_id)
  rescue => e 
    log.error e.message
    nil 
  end

  def verified?
    self.verification.nil?
  end

  def create_verification
    random = create_random_value
    self.verification = secure_hash("#{random}--#{email}")
  end

  def self.find_by_email(email)
    UserEmail.where(email: email).shift
  end

  def self.activate!(verification)
    return false if verification.nil? || verification.strip.empty?

    user_email = UserEmail.where(verification: verification).shift
    return false if user_email.nil?

    user_email.verification = nil
    user_email.save
    return true
  end

  private

    def create_random_value
      chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
      value = ''
      10.times { value << chars[rand(chars.size)] }
      value
    end

    def secure_hash(string)
      Digest::SHA2.hexdigest(string)
    end

end
