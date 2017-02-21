class Artefact < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  field :language     , type: String
  field :prod_key     , type: String
  field :version      , type: String
  field :group_id     , type: String
  field :artifact_id  , type: String
  field :classifier   , type: String
  field :packaging    , type: String
  field :prod_type    , type: String
  field :file         , type: String
  field :sha_value    , type: String
  field :sha_method   , type: String

  index({ sha_value: 1 }, { name: "sha_index", unique: true, drop_dups: true, background: true })

end
