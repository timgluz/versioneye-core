class InventoryItem < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  field :lpkv            , type: String # language:prod_key:version
  field :comp_key        , type: String # prod_key:version:license:sv_count
  field :project_id      , type: String
  field :project_language, type: String
  field :project_name    , type: String
  field :project_version , type: String
  field :project_group_id, type: String
  field :project_artifact_id, type: String
  field :project_teams   , type: String

  embedded_in :inventory

end
