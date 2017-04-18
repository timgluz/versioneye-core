require 'benchmark'
require 'dalli'

class GitPrWorker < Worker

  def work
    connection = get_connection
    connection.start
    channel = connection.create_channel
    channel.prefetch(1)
    queue   = channel.queue("git_pr_processor", :durable => true)

    multi_log " [*] GitPrWorker waiting for messages in #{queue.name}. To exit press CTRL+C"

    begin
      queue.subscribe(:manual_ack => true, :block => true) do |delivery_info, properties, body|
        multi_log " [x] GitPrWorker received #{body}"
        handle_pr body
        channel.ack(delivery_info.delivery_tag)
        multi_log " [x] GitPrWorker job done #{body}"
      end
    rescue => e
      log.error "ERROR in GitPrWorker: #{e.message}"
      log.error e.backtrace.join("\n")
      connection.close
    end
  end

  private

    def handle_pr msg
      sps         = message.split(":::")
      repo_name   = sps[0]
      branch      = sps[1]
      commits_url = sps[2]
      pr_nr       = sps[3]
      multi_log " [*] GitPrWorker - GithubPullRequestService.process #{repo_name}, #{branch}, #{commits_url}, #{pr_nr}"  
      GithubPullRequestService.process repo_name, branch, commits_url, pr_nr
      multi_log " [*] GitPrWorker - FINISHED GithubPullRequestService.process #{repo_name}, #{branch}, #{commits_url}, #{pr_nr}"  
    rescue => e
      log.error "ERROR in GitPrWorker! Input: #{message} Output: #{e.message}"
      log.error e.backtrace.join("\n")
    end

end