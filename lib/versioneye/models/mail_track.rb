class MailTrack < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  A_TEMPLATE_NEW_VERSION  = 'new_version_email'
  A_TEMPLATE_PROJECT_SV   = 'projects_security_email'
  A_TEMPLATE_NEWSLETTER   = 'newsletter'
  A_TEMPLATE_TEAM_NOTIFICATION = 'team_notification'

  field :user_id    , type: String
  field :template   , type: String
  field :period     , type: String
  field :project_id , type: String
  field :project_ids, type: Array
  field :team_id    , type: String
  field :orga_id    , type: String

  index({ user_id: 1, template: 1 }, { name: "user_id_template_index", background: true })
  index({ orga_id: 1, team_id: 1, template: 1, created_at: 1 }, { name: "team_noti_index", background: true })


  def self.add user_id, template_name, period, project_id = nil
    MailTrack.new(:user_id => user_id, :template => template_name, :period => period, :project_id => project_id ).save
  end


  def self.add_team template_name, orga_id = nil, team_id = nil, project_ids = nil
    MailTrack.new(:template => template_name, :orga_id => orga_id, :team_id => team_id, :project_ids => project_ids ).save
  end


  def self.send_team_email_already?(template_name, orga_id = nil, team_id = nil)
    time_ago = DateTime.now - 20.hours
    MailTrack.where(:template => template_name,
                    :orga_id => orga_id,
                    :team_id => team_id,
                    :created_at.gt => time_ago).count > 0
  end


  def user
    User.find self.user_id
  end


  def project
    Project.find self.project_id
  end

end
