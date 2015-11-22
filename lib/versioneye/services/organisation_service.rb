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


  def self.owner? orga, user
    return false if orga.nil? || user.nil?

    team = Team.where(:organisation_id => orga.ids, :name => Team::A_OWNERS).first
    return false if team.nil?

    team.members.each do |member|
      return true if member.user.ids.eql?(user.ids)
    end
    false
  end


  def self.member? orga, user
    return false if orga.nil? || user.nil?

    orga.teams.each do |team|
      team.members.each do |member|
        return true if member.user.ids.eql?(user.ids)
      end
    end
    false
  end


  def self.index user, only_owners = false
    tms = TeamMember.where(:user_id => user.ids)
    return [] if tms.empty?

    organisations = []
    orga_ids = []
    tms.each do |tm|
      next if only_owners == true && !tm.team.name.eql?(Team::A_OWNERS)
      
      orga = tm.team.organisation
      next if orga.nil?
      next if orga_ids.include?(orga.ids)

      orga_ids.push(orga.ids)
      organisations.push(orga)
    end
    organisations
  end


end
