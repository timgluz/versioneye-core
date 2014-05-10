require 'octokit'

class OctokitApi

  def self.application_authentication
    { :client_id => Settings.instance.github_client_id, :client_secret => Settings.instance.github_client_secret, :api_endpoint => Settings.instance.github_api_url }
  end

  def self.token_authentication token
    { :access_token => token, :api_endpoint => Settings.instance.github_api_url }
  end

  def self.client token = nil
    auth = self.application_authentication
    auth = self.token_authentication( token ) if token
    Octokit::Client.new( auth )
  end

end
