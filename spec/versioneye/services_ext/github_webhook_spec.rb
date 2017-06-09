require 'spec_helper'

describe GithubWebhook do
  test_hook_id = nil

  #NB! you must have set env var GITHUB_CLIENT_SECRET for that
  # aka register github APP or use oauth token
  let(:github_token){ Settings.instance.github_client_secret }
  let(:repo_fullname){ 'timgluz/versioneye-core' }
  let(:project_id){ 'test-project-id' }
  let(:api_key){ 'veye-api-key-123' }

  context "create and delete webhook" do
    it "saves a new hook" do
      VCR.use_cassette('github/webhooks/create') do
        configs = GithubWebhook.build_project_configs(project_id, api_key)
        res = GithubWebhook.create_webhook(repo_fullname, github_token, configs)

        expect(res).not_to be_nil
        expect(res[:id]).not_to be_nil
        expect(res[:name]).not_to be_nil

        expect(res[:name]).to eq('web')
        expect(res[:events]).to eq(['push', 'pull_request'])
        expect(res[:active]).to be_truthy
        expect(res[:config][:content_type]).to eq('json')
        expect(res[:config][:project_id]).to eq(project_id)
        expect(res[:config][:api_key]).to eq(api_key)

        test_hook_id = res[:id] #save hook id for deletion test
      end
    end

    it "deletes existing webhook" do
      expect(test_hook_id).not_to be_nil

      VCR.use_cassette('github/webhooks/delete') do
        res = GithubWebhook.delete_webhook(repo_fullname, github_token, test_hook_id)
        expect(res).to be_truthy
      end
    end

  end

  let(:hook_dt){
    {
      id: "1",
      url: "https://api.github.com/repos/octocat/Hello-World/hooks/1",
      test_url: "https://api.github.com/repos/octocat/Hello-World/hooks/1/test",
      ping_url: "https://api.github.com/repos/octocat/Hello-World/hooks/1/pings",
      name: "web",
      events: [ 'push', 'pull_request'],
      active: true,
      config: {
        url: "http://example.com/webhook",
        content_type: "json"
      }
    }
  }


  context "upsert_project_webhook" do
    it "saves a new project hook from response" do
      hook = GithubWebhook.upsert_project_webhook(hook_dt, repo_fullname, project_id)

      expect(hook).not_to be_nil
      expect(hook[:scm]).to eq(Webhook::A_TYPE_GITHUB)
      expect(hook[:fullname]).to eq(repo_fullname)
      expect(hook[:project_id]).to eq(project_id)
      expect(hook[:hook_id]).to eq(hook_dt[:id])
      expect(hook[:service_name]).to eq(hook_dt[:name])
      expect(hook[:active]).to eq(hook_dt[:active])
      expect(hook[:events]).to eq(hook_dt[:events])
      expect(hook[:config]).to eq(hook_dt[:config])
    end
  end

  context "create_project_hook" do
    it "creates a new hook and saves it onto DB" do
      VCR.use_cassette('github/webhooks/create') do
        expect(Webhook.all.size).to eq(0)

        GithubWebhook.create_project_hook(repo_fullname, project_id, api_key, github_token)

        expect(Webhook.all.size).to eq(1)
        hook = Webhook.all.first
        expect(hook).not_to be_nil
        expect(hook[:scm]).to eq(Webhook::A_TYPE_GITHUB)
        expect(hook[:fullname]).to eq(repo_fullname)
        expect(hook[:project_id]).to eq(project_id)
        expect(hook[:hook_id]).not_to be_nil
        expect(hook[:service_name]).to eq('web')
        expect(hook[:active]).to be_truthy
        expect(hook[:events]).to eq(hook_dt[:events])
      end
    end
  end

  context "delete_project_hook" do
    before do
      hook_dt[:id] = test_hook_id #use id from creation
      GithubWebhook.upsert_project_webhook(hook_dt, repo_fullname, project_id)
    end

    it "disconnect project and deletes Webhook" do
      VCR.use_cassette('github/webhooks/delete') do
        expect(Webhook.all.size).to eq(1)

        res = GithubWebhook.delete_project_hook(project_id, github_token )

        expect(res).to be_truthy
        expect(Webhook.all.size).to eq(0)
      end
    end
  end
end
