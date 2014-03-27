class Notification < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  field :version_id, type: String
  field :read      , type: Boolean, default: false
  field :sent_email, type: Boolean, default: false

  belongs_to :user
  belongs_to :product

  validates_presence_of :user_id   , :message => 'User is mandatory!'
  validates_presence_of :product_id, :message => 'Product is mandatory!'

  scope :all_not_sent, where(sent_email: false)
  scope :by_user     , ->(user){where(user_id: user.id)}
  scope :by_user_id  , ->(user_id){where(user_id: user_id).desc(:created_at).limit(30)}


  def self.unsent_user_notifications( user )
    Notification.where( sent_email: 'false', user_id: user.id )
  end

end
