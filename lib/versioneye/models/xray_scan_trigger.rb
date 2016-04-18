class XrayScanTrigger < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  field :language  , type: String
  field :prod_key  , type: String
  field :version   , type: String
  field :sv_name_id, type: String # Uniq. identifier
  field :hash      , type: String # sha256

end
