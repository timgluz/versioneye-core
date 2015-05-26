class ProjectCollaboratorService < Versioneye::Service

  
  # collaborator_info is either a username or a email address! 
  def self.add_new project, caller_user, collaborator_info 
    user = User.find_by_username( collaborator_info )
    user = by_email( collaborator_info ) if user.nil? 
    if user && ProjectCollaborator.collaborator?(project[:_id].to_s, user[:_id].to_s)
      raise "#{user[:fullname]} is already a collaborator in your project."
    end

    new_collaborator = ProjectCollaborator.new project_id: project[:_id].to_s,
                                               caller_id: caller_user[:_id].to_s,
                                               owner_id: project[:user_id].to_s, 
                                               period: project.period

    if user
      add_existing_user( project, new_collaborator, user ) 
    else 
      invite_user( project, new_collaborator, collaborator_info )
    end

    new_collaborator
  end


  def self.add_existing_user project, new_collaborator, user 
    new_collaborator[:active]  = true
    new_collaborator[:user_id] = user[:_id].to_s

    if new_collaborator.save == false 
      raise "Failure: can't add new collaborator - #{new_collaborator.errors.full_messages.to_sentence}"
    end

    project.collaborators << new_collaborator

    UserMailer.new_collaboration(new_collaborator).deliver
  end


  def self.invite_user project, new_collaborator, collaborator_info
    new_collaborator[:invitation_email] = collaborator_info
    new_collaborator[:invitation_code] = UserService.create_random_token

    if new_collaborator.save == false 
      raise "Failure: can't add new collaborator - #{new_collaborator.errors.full_messages.to_sentence}"
    end

    project.collaborators << new_collaborator

    if collaborator_info.to_s.match( User::A_EMAIL_REGEX )
      UserMailer.collaboration_invitation( new_collaborator ).deliver
    end
  end


  private 

    def self.by_email email 
      user = User.find_by_email( email )
      if user.nil? 
        ue = UserEmail.find_by_email( email )
        user = ue.user if ue && ue.verified?
      end
      user 
    end


end
