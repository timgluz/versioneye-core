class SyncStatus < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  field :object_type        , type: String
  field :object_id          , type: String
  field :status             , type: String

  index({ object_type: 1, object_id: 1 }, { name: "obj_type_id_index", unique: true, drop_dups: true, background: true })

  validates :object_type, presence: true
  validates :object_id, presence: true

end
