class Notification < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  field :version_id    , type: String
  field :read          , type: Boolean, default: false
  field :sent_email    , type: Boolean, default: false
  field :email_disabled, type: Boolean, default: false
  field :classification, type: String # nil for follow. Oterwise project.

  belongs_to :user
  belongs_to :product

  index({product_id: 1, user_id: 1, version_id: 1}, { name: "prod_user_vers_index", background: true, unique: true, drop_dups: true })
  index({user_id: 1}, { name: "user_index", background: true})
  index({user_id: 1, sent_email: 1}, { name: "user_unsent_index", background: true})

  validates_presence_of :user_id   , :message => 'User is mandatory!'
  validates_presence_of :product_id, :message => 'Product is mandatory!'

  scope :all_not_sent, ->{where(sent_email: false)}
  scope :by_user     , ->(user){where(user_id: user.id)}
  scope :by_user_id  , ->(user_id){where(user_id: user_id).desc(:created_at).limit(30)}


  def self.unsent_user_notifications( user )
    by_user( user ).all_not_sent
  end

end
