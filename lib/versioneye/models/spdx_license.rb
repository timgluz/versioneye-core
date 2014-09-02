class SpdxLicense < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  field :fullname    , type: String
  field :identifier  , type: String
  field :osi_approved, type: Boolean

  index({ fullname: 1 }  , { name: "fullname_index"  , background: true })
  index({ identifier: 1 }, { name: "identifier_index", background: true, unique: true })

end
