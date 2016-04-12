class BitbucketRepo < Versioneye::Model

  include Mongoid::Document

  field :name         , type: String
  field :fullname     , type: String
  field :user_login   , type: String
  field :owner_login  , type: String
  field :owner_type   , type: String
  field :language     , type: String
  field :description  , type: String
  field :private      , type: Boolean, default: false
  field :scm          , type: String
  field :html_url     , type: String # web url
  field :clone_url    , type: String # clone url
  field :size         , type: Integer
  field :branches     , type: Array
  field :project_files, type: Hash, default: nil
  field :created_at   , type: DateTime, default: DateTime.now
  field :updated_at   , type: DateTime, default: DateTime.now
  field :cached_at    , type: DateTime, default: DateTime.now

  belongs_to :user

  index({ user_id: 1 },     { name: "user_id_index"    , background: true })
  index({ name: 1 },        { name: "name_index"       , background: true })
  index({ fullname: 1 },    { name: "fullname_index"   , background: true })
  index({ language: 1 },    { name: "language_index"   , background: true })
  index({ owner_login: 1 }, { name: "owner_login_index", background: true })
  index({ owner_type: 1 },  { name: "owner_type_index" , background: true })

  scope :by_language    , ->(lang){where(language: lang)}
  scope :by_user        , ->(user){where(user_id: user[:_id])}
  scope :by_owner_login , ->(owner){where(owner_login: owner)}
  scope :by_fullname    , ->(name){where(fullname: name)}


  def self.revision_for user, fullname, branch, filename
    repo = BitbucketRepo.where(:user_id => user.id.to_s, :fullname => fullname).first
    repo.project_files[branch].each do |files|
      return files["revision"] if files["path"].eql?(filename)
    end
    nil
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    nil
  end

  def self.get_owner_type(user, owner_info)
    owner_type = 'team'
    if user[:bitbucket_id] == owner_info[:username]
      owner_type = 'user'
    end

    return owner_type
  end

  def self.build_or_update( user, repo )
    return nil if repo.nil? || repo.empty?

    repo = repo.deep_symbolize_keys if repo.respond_to?("deep_symbolize_keys")

    owner_info = repo[:owner]
    owner_type = get_owner_type(user, owner_info)
    repo_links = repo[:links]
    fullname = repo[:full_name]
    fullname = repo[:fullname] if fullname.to_s.empty?

    repo = BitbucketRepo.find_or_create_by(:user_id => user.id.to_s, :fullname => fullname)
    repo.update_attributes!({
      user_login: user[:bitbucket_id],
      name: repo[:name],
      scm: repo[:scm],
      owner_login: owner_info[:username],
      owner_type: owner_type,
      language: repo[:language].to_s.downcase,
      description: repo[:description],
      private: repo[:is_private],
      html_url: repo_links[:html][:href],
      clone_url: repo_links[:clone].to_a.last[:href],
      size: repo[:size]

      # This will be completed by bitbucket_repo_import_worker or have to be set from extern.
      # branches: repo_branches,
      # project_files: project_files,
    })

    repo
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    nil
  end

end
