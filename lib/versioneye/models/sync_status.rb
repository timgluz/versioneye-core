class SyncStatus < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  field :comp_type        , type: String
  field :comp_id          , type: String
  field :status             , type: String, default: 'done'
  field :info               , type: String

  index({ comp_type: 1, comp_id: 1 }, { name: "obj_type_id_index", unique: true, drop_dups: true, background: true })

  validates :comp_type, presence: true
  validates :comp_id, presence: true

end
