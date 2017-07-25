class InventoryDiff < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  field :organisation_id, type: String
  field :items_added    , type: Array
  field :items_removed  , type: Array
  field :finished       , type: Boolean, :default => false

  field :inventory1_id, type: String
  field :inventory2_id, type: String


  def inventory1
    Inventory.find inventory1_id
  end

  def inventory2
    Inventory.find inventory2_id
  end

end
