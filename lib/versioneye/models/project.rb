class Project < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  A_TYPE_RUBYGEMS  = 'RubyGem'
  A_TYPE_PIP       = 'PIP'
  A_TYPE_NPM       = 'npm'
  A_TYPE_COMPOSER  = 'composer'
  A_TYPE_GRADLE    = 'gradle'
  A_TYPE_SBT       = 'sbt'
  A_TYPE_MAVEN2    = 'Maven2'
  A_TYPE_LEIN      = 'Lein'
  A_TYPE_BOWER     = 'Bower'
  A_TYPE_GITHUB    = 'GitHub'
  A_TYPE_R         = 'R'
  A_TYPE_COCOAPODS = 'CocoaPods'
  A_TYPE_BIICODE   = 'Biicode'

  A_SOURCE_UPLOAD    = 'upload'
  A_SOURCE_URL       = 'url'
  A_SOURCE_GITHUB    = 'github'
  A_SOURCE_BITBUCKET = 'bitbucket'
  A_SOURCE_STASH     = 'stash'
  A_SOURCE_API       = 'API'  # TODO use this to replace property :api_created

  A_PERIOD_MONTHLY = 'monthly'
  A_PERIOD_WEEKLY  = 'weekly'
  A_PERIOD_DAILY   = 'daily'

  field :name       , type: String
  field :description, type: String
  field :license    , type: String

  field :group_id   , type: String # Maven specific
  field :artifact_id, type: String # Maven specific

  field :project_type  , type: String,  :default => A_TYPE_MAVEN2
  field :language      , type: String
  field :project_key   , type: String
  field :period        , type: String,  :default => A_PERIOD_DAILY
  field :notify_after_api_update, type: Boolean, :default => false
  field :email         , type: String
  field :url           , type: String
  field :source        , type: String,  :default => A_SOURCE_UPLOAD
  field :s3_filename   , type: String
  field :allow_zero_deps, type: Boolean, :default => false

  field :scm_fullname  , type: String # repo name, for example 'reiz/gemify'
  field :scm_branch    , type: String, default: "master"
  field :scm_revision  , type: String

  field :dep_number      , type: Integer, :default => 0
  field :out_number      , type: Integer, :default => 0
  field :unknown_number  , type: Integer, :default => 0
  field :licenses_red    , type: Integer, :default => 0
  field :licenses_unknown, type: Integer, :default => 0

  # These are the numbers summed up from all children 
  field :dep_number_sum      , type: Integer, :default => 0
  field :out_number_sum      , type: Integer, :default => 0
  field :unknown_number_sum  , type: Integer, :default => 0
  field :licenses_red_sum    , type: Integer, :default => 0
  field :licenses_unknown_sum, type: Integer, :default => 0

  field :public         , type: Boolean, :default => false  # visible for everybody
  field :private_project, type: Boolean, :default => false  # private project from GitHub/Bitbucket
  field :api_created    , type: Boolean, :default => false  # this project was created through the VersionEye API
  field :parent_id      , type: String,  :default => nil    # id of the parent project. 

  field :license_whitelist_id, type: String

  validates :name       , presence: true
  validates :project_key, presence: true

  belongs_to :user
  has_many   :projectdependencies
  has_many   :collaborators, class_name: 'ProjectCollaborator'

  index({project_key: 1, project_type: 1}, { name: "key_type_index",  background: true})
  index({user_id: 1, private_project: 1},  { name: "user_id_private_index", background: true})
  index({user_id: 1}, { name: "user_id_index", background: true})
  index({name: 1},    { name: "name_index",    background: true})
  index({source: 1},  { name: "source_index",  background: true})

  scope :by_collaborator, ->(user){ all_in(_id: ProjectCollaborator.by_user(user).to_a.map(&:project_id)) }
  scope :by_user   , ->(user)    { where(user_id: user[:_id].to_s) }
  scope :by_user_id, ->(user_id) { where(user_id: user_id.to_s) }
  scope :by_id     , ->(id)      { where(_id: id.to_s) }
  scope :by_source , ->(source)  { where(source:  source ) }
  scope :by_period , ->(period)  { where(period:  period ) }
  scope :parents   , -> { where(parent_id: nil ) }
  scope :by_github , ->(reponame){ where(source: A_SOURCE_GITHUB, scm_fullname: reponame) }

  attr_accessor :lwl_pdf_list, :has_kids

  def to_s
    "<Project #{language}/#{project_type} #{name}>"
  end

  def parent 
    Project.find parent_id
  end 

  def children 
    Project.where(:parent_id => self.id.to_s)
  end

  def scopes 
    return [] if self.projectdependencies.nil? || self.projectdependencies.empty?
    scopes = []
    self.projectdependencies.each do |dependency| 
      scopes << dependency.scope if !scopes.include?( dependency.scope )
    end
    scopes
  end

  def dependencies(scope = nil)
    return self.projectdependencies if scope.nil? 
    return self.projectdependencies if self.projectdependencies.nil? || self.projectdependencies.empty?
    deps = []
    self.projectdependencies.each do |dependency| 
      deps << dependency if dependency.scope.eql?(scope)
    end
    deps
  end

  def sorted_dependencies_by_rank( deps = nil )
    deps = self.dependencies if deps.nil? 
    return deps if deps.nil? or deps.empty?
    deps.sort_by {|dep| dep[:status_rank] }
  end

  def unmuted_dependencies
    deps = self.projectdependencies
    return nil if deps.nil?
    deps.any_in(muted: [false, nil])
  end

  def muted_dependencies
    deps = self.projectdependencies
    return nil if deps.nil?
    deps.any_in(muted: [true])
  end

  def self.find_by_id( id )
    Project.find( id )
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    nil
  end

  def self.find_by_ga( group_id, artifact_id )
    Project.where(:group_id => group_id, :artifact_id => artifact_id).first
  end

  def filename
    self.s3_filename.to_s.gsub(/\A\S+\_/, "")
  end

  def self.private_project_count_by_user user_id
    Project.where( user_id: user_id, private_project: true ).count
  end

  def show_dependency_badge?
    true 
  end

  def visible_for_user?(user)
    return true  if self[:public]
    return false if user.nil?
    return true  if self.user_id.to_s == user[:_id].to_s
    return true  if ProjectCollaborator.collaborator?(self[:_id], user[:_id])
    return false
  end

  def collaborator( user )
    return nil if user.nil?
    return nil if collaborators.nil? || collaborators.size == 0
    collaborators.each do |collaborator|
      return collaborator if user._id.to_s.eql?( collaborator.user_id.to_s )
    end
    nil
  end

  def license_whitelist
    return nil if license_whitelist_id.to_s.empty?
    LicenseWhitelist.find license_whitelist_id
  rescue => e
    log.error e.message
    nil
  end

  def collaborator?( user )
    return false if user.nil?
    return true if !self.user.nil? && self.user.username.eql?( user.username )
    !collaborator( user ).nil?
  end

  def remove_collaborators
    collaborators.each { |collaborator| collaborator.remove }
  end

  def known_dependencies
    self.projectdependencies.find_all {|dep| dep.prod_key }
  end

  def remove_dependencies
    projectdependencies.each { |dependency| dependency.remove }
  end

  def save_dependencies
    projectdependencies.each { |dependency| dependency.save }
  end

  def muted_prod_keys
    prod_keys = Array.new
    muted_deps = muted_dependencies
    muted_deps.each do |dep|
      key = dep_key(dep)
      prod_keys.push key
    end
    prod_keys
  end

  def overwrite_dependencies( new_dependencies )
    muted_keys = muted_prod_keys
    remove_dependencies
    new_dependencies.each do |dep|
      key = dep_key(dep)
      dep.muted = true if muted_keys.include?( key )
      projectdependencies.push dep
      dep.save
    end
  end

  def make_project_key!
    if self.project_key.to_s.empty?
      self.project_key = make_project_key
    end
  end

  def make_project_key
    return Project.create_random_value() if self.user.nil?

    project_nr = 1
    project_key_text = "#{self.project_type}_#{self.name}".downcase
    project_key_text.gsub!(/[\s|\W|\_]+/, "_")
    if project_key_text.to_s.empty?
      project_key_text = Project.create_random_value()
    end

    similar_projects = Project.by_user(self.user).where(
                        project_key: Regexp.new("#{project_key_text}"),
                        project_type: self.project_type
                      )
    project_nr += similar_projects.count unless similar_projects.nil?
    "#{project_key_text}_#{project_nr}"
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    Project.create_random_value
  end

  def update_from new_project
    return nil if new_project.nil?

    if new_project.dependencies && !new_project.dependencies.empty?
      self.overwrite_dependencies( new_project.dependencies )
    end
    self.description    = new_project.description
    self.license        = new_project.license
    self.url            = new_project.url
    if new_project.s3_filename
      self.s3_filename  = new_project.s3_filename
    end
    self.dep_number     = new_project.dep_number
    self.out_number     = new_project.out_number
    self.unknown_number = new_project.unknown_number
    self.save
  end

  def self.email_for(project, user)
    return user.email if project.email.to_s.empty?

    user_email = user.get_email( project.email )
    return user_email.email if user_email && user_email.verified?

    return user.email
  end

  def self.create_random_value
    chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    value = ""
    20.times { value << chars[rand(chars.size)] }
    value
  end

  def sum_own!
    self.dep_number_sum       = self.dep_number
    self.out_number_sum       = self.out_number
    self.unknown_number_sum   = self.unknown_number
    self.licenses_red_sum     = self.licenses_red
    self.licenses_unknown_sum = self.licenses_unknown
    self.save 
  end

  def sum_reset!
    self.dep_number_sum       = 0
    self.out_number_sum       = 0
    self.unknown_number_sum   = 0
    self.licenses_red_sum     = 0
    self.licenses_unknown_sum = 0
    self.save 
  end

  def get_binding
    binding()
  end

  private

    def dep_key dep
      "#{dep.language}_#{dep.prod_key}_#{dep.version_current}"
    end

end
