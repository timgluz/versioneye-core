require 'octokit'

class OctokitApi

  def self.application_authentication
    { :client_id => Settings.instance.github_client_id, :client_secret => Settings.instance.github_client_secret }
  end

  # Singleton pattern
  def self.client
    Octokit::Client.new( self.application_authentication )
  end

  # Singleton pattern
  def self.instance
    self.client
  end

end
