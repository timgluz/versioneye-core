class SpdxLicense < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  field :fullname    , type: String
  field :identifier  , type: String
  field :osi_approved, type: Boolean

  index({ fullname: 1 }  , { name: "fullname_index"  , background: true })
  index({ identifier: 1 }, { name: "identifier_index", background: true, unique: true, drop_dups: true })


  def to_s
    "#{identifier} - #{fullname} - #{osi_approved}"
  end

  def self.identifier_by_fullname_regex name
    SpdxLicense.where(:fullname => /\A#{name.strip}\z/i ).first
  rescue => e
    log.error e
    # log.error e.backtrace.join("\n")
    nil
  end


  def self.identifier_by_regex name
    SpdxLicense.where(:identifier => /\A#{name.strip}\z/i ).first
  rescue => e
    log.error e
    # log.error e.backtrace.join("\n")
    nil
  end


end
