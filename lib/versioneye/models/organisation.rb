class Organisation < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :company, type: String
  field :location, type: String
  field :email, type: String
  field :website, type: String

  has_many :projects
  has_many :teams
  has_many :license_whitelists
  has_many :component_whitelists

  validates_presence_of :name, :message => 'is mandatory!'
  validates_uniqueness_of :name, :message => 'exist already.'

  index({ name: 1 }, { name: "name_index", background: true, unique: true })

  def to_s
    name
  end

  def to_param
    name
  end

  def owner_team
    teams.each do |team|
      return team if team.name.eql?(Team::A_OWNERS)
    end
    nil
  end

  def team_by name
    teams.each do |team|
      return team if team.name.eql?(name)
    end
    nil
  end

  def unknown_license_deps
    deps = []
    projects.each do |project|
      pdeps = project.unknown_license_deps
      pdeps.each do |dep|
        next if deps.include?( dep.to_s )
        deps.push dep.to_s
        p dep.to_s
      end
    end
    deps
  end

end
