class EsUser < Versioneye::Service

  def self.create_index_with_mappings
    Tire.index(Settings.instance.elasticsearch_user_index) do
      create :mappings => {
        :user => {
          :properties => {
            :_id => {type: 'string', analyzer: 'keyword', include_in_all: false},
            :fullname => {type: 'string', analyzer: 'snowball', boost: 1},
            :username => {type: 'string', analyzer: 'snowball', boost: 100}
          }
        }
      }
    end
  end

  #-- search
  def self.search(term, results_per_page = 10)
    q = term || '*'
    s = Tire.search(Settings.instance.elasticsearch_user_index,
                    load: true,
                    search_type: 'dfs_query_and_fetch',
                    size: results_per_page) do |search|
      search.query do |query|
        query.string "#{ q }*"
      end
    end

    s.results
  end

  #--  admin funcs
  def self.clean_all
    Tire.index( Settings.instance.elasticsearch_user_index ).delete
  end

  def self.reset
    self.clean_all
    self.create_index_with_mappings
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end

  def self.refresh
    Tire.index( Settings.instance.elasticsearch_user_index ).refresh
  end

  def self.index_all
    UserService.all_users_paged do |users|
      bulk_index users
    end
    self.refresh
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end

  def self.reindex_all
    self.reset
    self.index_all
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end

  def self.bulk_index users
    Tire.index Settings.instance.elasticsearch_user_index do
      json_users = users.map{|user| user.to_indexed_json}
      import json_users
    end
  end

  def self.index(user)
    log.info "indexing: #{user[:username]}"
    Tire.index Settings.instance.elasticsearch_user_index do
      store user.to_indexed_json
    end
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end

end
