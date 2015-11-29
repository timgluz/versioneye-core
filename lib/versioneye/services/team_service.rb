class TeamService < Versioneye::Service


  def self.delete team
    return false if team.nil?

    team.members.delete_all
    team.delete
  end


end
