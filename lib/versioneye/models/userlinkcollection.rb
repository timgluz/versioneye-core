class Userlinkcollection < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  A_LINKEDIN      = 'http://www.linkedin.com/in/'
  A_XING          = 'http://www.xing.com/profile/'
  A_GITHUB        = 'https://github.com/'
  A_STACKOVERFLOW = 'http://stackoverflow.com/users/'
  A_TWITTER       = 'https://twitter.com/#!/'
  A_FACEBOOK      = 'http://www.facebook.com/people/'

  field :user_id,       type: String
  field :linkedin,      type: String, :default => A_LINKEDIN
  field :xing,          type: String, :default => A_XING
  field :github,        type: String, :default => A_GITHUB
  field :stackoverflow, type: String, :default => A_STACKOVERFLOW
  field :twitter,       type: String, :default => A_TWITTER
  field :facebook,      type: String, :default => A_FACEBOOK

  def self.find_all_by_user(user_id)
    return nil if user_id.nil? || user_id.to_s.strip.empty?
  	Userlinkcollection.where( user_id: user_id ).shift
  end

  def linkedin_url
    return linkedin if linkedin.match(/\Ahttp:\/\//) || linkedin.match(/\Ahttps:\/\//)
    "http://#{linkedin}"
  end

  def xing_url
    return xing if xing.match(/\Ahttp:\/\//) || xing.match(/\Ahttps:\/\//)
    "http://#{xing}"
  end

  def github_url
    return github if github.match(/\Ahttp:\/\//) || github.match(/\Ahttps:\/\//)
    "https://#{github}"
  end

  def stackoverflow_url
    return stackoverflow if stackoverflow.match(/\Ahttp:\/\//) || stackoverflow.match(/\Ahttps:\/\//)
    "http://#{stackoverflow}"
  end

  def twitter_url
    return twitter if twitter.match(/\Ahttp:\/\//) || twitter.match(/\Ahttps:\/\//)
    "https://#{twitter}"
  end

  def facebook_url
    return facebook if facebook.match(/\Ahttp:\/\//) || facebook.match(/\Ahttps:\/\//)
    "https://#{facebook}"
  end

  def empty?
  	linkedin_empty? && xing_empty? && github_empty? &&
    stackoverflow_empty? && twitter_empty? && facebook_empty?
  end

  def linkedin_empty?
    self.linkedin.nil? || self.linkedin.empty? || self.linkedin.eql?(A_LINKEDIN)
  end
  def xing_empty?
    self.xing.nil? || self.xing.empty? || self.xing.eql?(A_XING)
  end
  def github_empty?
    self.github.nil? || self.github.empty? || self.github.eql?(A_GITHUB)
  end
  def stackoverflow_empty?
    self.stackoverflow.nil? || self.stackoverflow.empty? || self.stackoverflow.eql?(A_STACKOVERFLOW)
  end
  def twitter_empty?
    self.twitter.nil? || self.twitter.empty? || self.twitter.eql?(A_TWITTER)
  end
  def facebook_empty?
    self.facebook.nil? || self.facebook.empty? || self.facebook.eql?(A_FACEBOOK)
  end

end
