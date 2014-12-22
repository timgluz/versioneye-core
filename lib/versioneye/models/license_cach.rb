class LicenseCach < Versioneye::Model 

  include Mongoid::Document
  include Mongoid::Timestamps

  field :name      , type: String # For example MIT
  field :url       , type: String # URL to the license text

  # true  = it's conform with the license whitelist of the project
  # false = it violates the license whitelist of the project 
  # nil   = There is no license white list defined in the project 
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
