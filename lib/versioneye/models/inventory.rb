class Inventory < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  field :inventory_name , type: String
  field :orga_name      , type: String
  field :team_name      , type: String
  field :language       , type: String
  field :project_version, type: String
  field :post_filter    , type: String

  index({ orga_name: 1, team_name: 1, language: 1, project_version: 1, post_filter: 1 }, { name: "inv_uni_index", unique: true, background: true, drop_dups: true })
  index({ orga_name: 1}, { name: "orga_name_index",  unique: false, background: true, drop_dups: false })

  embeds_many :inventory_items

end
