class OrganisationService < Versioneye::Service

  def self.create_new user, name
    orga = Organisation.new({:name => name})
    orga.save
    team = Team.new(:name => Team::A_OWNERS)
    team.add_member user
    team.organisation = orga
    team.save
    orga
  end

end
