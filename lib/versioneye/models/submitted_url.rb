class SubmittedUrl < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  field :url             , type: String
  field :message         , type: String
  field :user_id         , type: String
  field :user_email      , type: String
  field :search_term     , type: String
  field :declined        , type: Boolean
  field :declined_message, type: String
  field :integrated      , type: Boolean, default: false

  belongs_to :product_resource

  validates :url       , presence: true
  validates :message   , presence: true
  validates :user_email, format: {with: /\A([^@\s]+)@((?:[-a-z0-9]+.)+[a-z]{2,})\z/i, :allow_blank => true}

  scope :as_unchecked     , -> { where(declined: nil) }
  scope :as_checked       , -> { where(:declined.in => [false, true]) }
  scope :as_accepted      , -> { where(declined: false) }
  scope :as_declined      , -> { where(declined: true) }
  scope :as_not_integrated, -> { where(integrated: false) }


  def to_s
    "<SubmittedUrl> url: #{url}, declined: #{declined}, integrated: #{integrated}, product_resource: #{product_resource_id.to_s}"
  end

  def self.find_by_id(id)
    return nil if id.to_s.strip.empty?
    return self.find(id.to_s) if self.where(_id: id.to_s).exists?
  end

  def user
    User.find_by_id user_id
  end

  def url_guessed
    unless url.match(/https:\/\/github.com\//).nil?
      new_url = url.gsub('https://github.com/', 'https://api.github.com/repos/')
      unless new_url.match("\/$").nil?
        return new_url[0..-2]
      end
      return new_url
    end
    url
  end

  def name_guessed
    unless url.match(/https:\/\/github.com\//).nil?
      name = url.gsub('https://github.com/', '')
      unless name.match("\/$").nil?
        return name[0..-2]
      end
      return name
    end
    url
  end

  def type_guessed
    return "GitHub" if !url.match(/github.com/).nil?
    ""
  end

end
