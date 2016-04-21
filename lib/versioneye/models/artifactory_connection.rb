class ArtifactoryConnection < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  field :art_user   , type: String
  field :art_pass   , type: String
  field :art_id     , type: String
  field :art_url    , type: String
  field :art_token  , type: String
  field :art_enabled, type: Boolean

  validates :art_user , presence: true
  validates :art_pass , presence: true
  validates :art_id   , presence: true
  validates :art_url  , presence: true
  validates :art_token, presence: true

end
