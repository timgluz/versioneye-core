class UserPermission < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  field :lwl, type: Boolean, default: false # allowed to manage license whitelists 

  belongs_to :user

end
