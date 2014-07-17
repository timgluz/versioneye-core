class Reference  < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  field :language, type: String
  field :prod_key, type: String
  field :version,  type: String
  field :ref_count, type: Integer

  has_many :products

end
