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

  # TODO email
  def self.send_notifications
    count = 0
    user_ids = Notification.all.distinct(:user_id)
    user_ids.each do |id|
      user = User.find_by_id( id )
      next if user.nil?
      if user.deleted
        self.remove_notifications user
      else
        count += 1 if self.send_unsend_notifications user
      end
    end
    # NotificationMailer.status( count ).deliver
    log.info "Send out #{count} emails"
    count
  end

  # TODO email
  def self.send_unsend_notifications user
    notifications = self.unsent_user_notifications user
    return false if notifications.nil? || notifications.empty?

    notifications.sort_by {|notice| [notice.product.language]}
    # NotificationMailer.new_version_email( user, notifications ).deliver
    log.info "send notifications for user #{user.fullname} start"
    return true
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    return false
  end

  def self.remove_notifications user
    log.info " -- No user found for id: #{user.id} "
    notifications = Notification.where( :user_id => user.id )
    notifications.each do |notification|
      log.info " ---- Remove notification for user id: #{user.id} "
      notification.remove
    end
  end

end
