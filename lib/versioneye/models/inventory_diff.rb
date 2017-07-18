class InventoryDiff < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  field :organisation_id, type: String
  field :items_added    , type: Array
  field :items_removed  , type: Array
  field :finished       , type: Boolean, :default => false

end
