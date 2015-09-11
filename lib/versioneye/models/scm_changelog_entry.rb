class ScmChangelogEntry < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  field :language   , type: String
  field :prod_key   , type: String
  field :version    , type: String

  field :change_date  , type: DateTime, :default => DateTime.now
  field :author       , type: String
  field :action       , type: String
  field :file         , type: String
  field :revision     , type: String
  field :revision_base, type: String
  field :message      , type: String

end
