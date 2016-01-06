class SapTeamUserImporter

  def self.process filepath = "/Users/reiz/SAP-ECP-DLs.csv", orga_name = "ecp"
    orga = Organisation.where(:name => orga_name).first
    CSV.foreach(filepath) do |row|
      team_name  = row[0].gsub(" ", "_").downcase
      last_name  = row[1]
      first_name = row[2]
      email      = row[3]

      user = create_user last_name, first_name, email
      team = create_team orga, team_name
      team.add_member user
    end
  end


  def self.create_user last_name, first_name, email
    user = User.find_by_email email
    return user if user

    user = User.new
    user.username = "#{first_name}_#{last_name}".downcase
    user.cleanup_username
    user.ensure_unique_username
    user.fullname = "#{first_name}_#{last_name}"
    user.email = email
    user.terms = true
    user.datenerhebung = true
    user.save
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
