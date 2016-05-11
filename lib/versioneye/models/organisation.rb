class Organisation < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  field :name,     type: String
  field :company,  type: String
  field :location, type: String
  field :email,    type: String
  field :website,  type: String

  field :mattp,    type: Boolean, default: false # mattp = member allowed to transfer projects
  field :matattp,  type: Boolean, default: false # mattp = member allowed to assign teams to projects

  has_many :projects
  has_many :teams
  has_many :license_whitelists
  has_many :component_whitelists

  validates_presence_of   :name, :message => 'is mandatory!'
  validates_uniqueness_of :name, :message => 'exist already.'

  index({ name: 1 }, { name: "name_index", background: true, unique: true })

  def to_s
    name
  end

  def default_lwl_id
    return nil if license_whitelists.nil? || license_whitelists.empty?

    license_whitelists.each do |lwl|
      return lwl.ids if lwl.default == true
    end
    nil
  end

  def default_cwl_id
    return nil if component_whitelists.nil? || component_whitelists.empty?

    component_whitelists.each do |cwl|
      return cwl.ids if cwl.default == true
    end
    nil
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

  def teams_by user
    ts = []
    teams.each do |team|
      team.members.each do |member|
        ts << team if member.user.ids.eql?(user.ids)
      end
    end
    ts
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
        prod_key = dep.prod_key
        prod_key = "#{dep.group_id}/#{dep.artifact_id}" if prod_key.to_s.empty?
        k = "#{dep.language}:#{prod_key}:#{dep.version_requested}"
        next if deps.include?( k )
        next if k.match(/com\.hybris/)
        deps.push k
        p "#{k} - #{dep.ids}"
      end
    end
    deps
  end


  def component_list
    return nil if projects.to_a.empty?

    comps = {}
    projects.each do |project|
      collect_components project, comps
      next if project.children.count == 0

      project.children.each do |child|
        collect_components child, comps
      end
    end

    comps
  end


  private


    def collect_components project, comps
      project.dependencies.each do |dep|
        key = "#{dep.language}:#{dep.possible_prod_key}:#{dep.version_requested}"
        comps[key] = [] if !comps.keys.include?( key )
        val = "#{project.language}:#{project.name}:#{project.ids}"
        comps[key] << val if !comps[key].include?( val )
      end
    end

end
