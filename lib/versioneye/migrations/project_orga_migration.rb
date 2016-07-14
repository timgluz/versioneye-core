class ProjectOrgaMigration < Versioneye::Service

  def self.migrate
    mp = 0
    UserService.all_users_paged do |users|
      users.each do |user|
        next if user.projects.empty?

        orga = Organisation.where(:name => "#{user.username}_orga").first
        if orga.nil?
          orgas = OrganisationService.index(user, true)
          orga  = orgas.first if orgas.count == 1
        end
        next if orga.nil?

        user.projects.each do |project|
          OrganisationService.transfer project, orga
          mp += 1
          p "migrated #{project.name} to #{orga.name} - #{mp}"
        end
      end
    end
    p mp
    mp
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end

end
