class OrganisationService < Versioneye::Service


  def self.create_new user, name
    if !Organisation.where({:name => name.downcase}).empty?
      raise "Organisation with name '#{name}' exists already. Please choose another name."
    end
    orga = Organisation.new({:name => name.downcase})
    orga.save
    team = Team.new(:name => Team::A_OWNERS)
    team.add_member user
    team.organisation = orga
    team.save
    orga
  end


  def self.index user
    tms = TeamMember.where(:user_id => user.ids)
    return [] if tms.empty?

    organisations = []
    orga_ids = []
    tms.each do |tm|
      orga = tm.team.organisation
      next if orga_ids.include?(orga.ids)

      orga_ids.push(orga.ids)
      organisations.push(orga)
    end
    organisations
  end


end
