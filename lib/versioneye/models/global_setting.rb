class GlobalSetting < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  field :environment , type: String, default: 'development'
  field :key         , type: String, default: 'RAILS_ENV'
  field :value       , type: String, default: 'development'

  index({ environment: 1, key: 1, value: 1 }, { unique: true })


  def self.get env, key
    return nil if env.to_s.empty? || key.to_s.empty?

    gs = GlobalSetting.where(:environment => env, :key => key.upcase).first
    return nil if gs.nil?

    gs.value
  end


  def self.set env, key, value
    return nil if env.to_s.empty? || key.to_s.empty? || value.to_s.empty?

    gs = GlobalSetting.where(:environment => env, :key => key.upcase).first
    if gs.nil?
      gs = GlobalSetting.new(:environment => env, :key => key.upcase)
    end
    gs.value = value
    gs.save
  end


end
