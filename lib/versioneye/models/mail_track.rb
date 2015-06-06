class MailTrack < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id    , type: String
  field :template   , type: String
  field :period     , type: String
  field :project_id , type: String

  index({ user_id: 1, template: 1 }, { name: "user_id_template_index", background: true })

  def self.add user_id, template_name, period, project_id = nil
    MailTrack.new(:user_id => user_id, :template => template_name, :period => period, :project_id => project_id ).save 
  end

  def self.send_already? user_id, template_name, period
    mails = fetch_by user_id, template_name, period
    !mails.empty?
  end

  def self.fetch_by user_id, template_name, period
    time_ago = date_for period
    MailTrack.where(:user_id => user_id, :template => template_name, :period => period, :created_at.gt => time_ago)
  end

  def self.date_for period 
    if period.eql?(Project::A_PERIOD_DAILY)
      return DateTime.now - 24.hours
    elsif period.eql?(Project::A_PERIOD_WEEKLY)
      return DateTime.now - 1.week
    else 
      return DateTime.now - 1.month
    end
  end  

end
