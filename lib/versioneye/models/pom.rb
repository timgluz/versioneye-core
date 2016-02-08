class Pom < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  field :url    , type: String

  index({ url: 1 }, { name: "url_index", unique: true, background: true, drop_dups: true })

  validates :url, presence: true

end
