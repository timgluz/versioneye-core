class SapTeamUserImporter


  def self.process filepath = "/Users/reiz/SAP-ECP-DLs.csv", orga_name = "ecp"
    orga = Organisation.where(:name => orga_name).first
    CSV.foreach(filepath) do |row|
      team_name  = row[0].gsub(" ", "-").downcase
      email      = row[1]
      next if email.match(/@/).nil?

      name = email.split("@").first

      user = create_user name, email
      team = create_team orga, team_name
      team.add_member user
    end
  end


  def self.create_user name, email
    user = User.find_by_email email
    return user if user

    user = User.new
    user.username = name.downcase.gsub(".", "_")
    user.cleanup_username
    user.ensure_unique_username
    user.fullname = name.gsub(".", " ")
    user.email = email
    user.terms = true
    user.datenerhebung = true
    user.save
    user.update_password user.username
    user
  end


  def self.create_team orga, team_name
    team = Team.where(:organisation_id => orga.ids, :name => team_name).first
    return team if team

    team = Team.new({ :name => team_name, :organisation_id => orga.id })
    team.save
    team
  end


end
