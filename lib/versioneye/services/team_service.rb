class TeamService < Versioneye::Service


  def self.delete team
    return false if team.nil?

    team.members.delete_all
    team.delete
  end


  def self.add team_name, orga_id, username, owner
    orga = Organisation.find orga_id
    team = Team.where(:name => team_name, :organisation_id => orga_id).first
    user = User.find_by_username username
    team.add_member user
    TeamMailer.add_new_member(orga, team, user, owner).deliver
    true
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    false
  end


end
