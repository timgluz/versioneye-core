class LicenseCach < Versioneye::Model 

  include Mongoid::Document
  include Mongoid::Timestamps

  field :name      , type: String # For example MIT
  field :url       , type: String # URL to the license text
  field :on_whitelist, type: Boolean
  
  field :license_id, type: String 

  embedded_in :projectdependency

  def link 
    url 
  end

  def name_substitute 
    name 
  end

end 
