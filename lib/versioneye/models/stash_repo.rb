class StashRepo < Versioneye::Model

  include Mongoid::Document

  field :stash_id     , type: String
  field :slug         , type: String
  field :name         , type: String
  field :fullname     , type: String
  field :scmId        , type: String
  field :state        , type: String
  field :statusMessage, type: String
  field :project_key  , type: String
  field :forkable     , type: Boolean
  field :public_repo  , type: Boolean
  field :branches     , type: Array
  field :project_files, type: Hash

  belongs_to :user

  index({ user_id: 1 },  { name: "user_id_index", background: true })
  index({ fullname: 1 }, { name: "fullname_index", background: true })

  scope :by_user, ->(user){where(user_id: user._id)}
  scope :by_fullname, ->(name){where(fullname: name)}


  def self.build_or_update user, repo_data
    return nil if repo_data.nil? || repo_data.empty? || user.nil?

    repo_data = repo_data.deep_symbolize_keys
    project_key = repo_data[:project][:key]
    fullname = "#{project_key}/#{repo_data[:name]}"

    repo = StashRepo.find_or_create_by(:user_id => user._id.to_s, :stash_id => repo_data[:id])
    repo.update_attributes!({
      slug: repo_data[:slug],
      name: repo_data[:name],
      fullname: fullname,
      scmId: repo_data[:scmId],
      state: repo_data[:state],
      statusMessage: repo_data[:statusMessage],
      forkable: repo_data[:forkable],
      public_repo: repo_data[:public],
      project_key: project_key
    })
    repo
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    nil
  end


end
