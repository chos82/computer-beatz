class ProjectMembershipMailer < ActionMailer::Base
  
  def declined_notification(project_membership, recipient)
    setup_email(project_membership, recipient)
    
    @body[:decliner] = User.find(project_membership.user_id).login
  end
  
  def new_member_notification(project_membership, recipient)
    setup_email(project_membership, recipient)
    
    @body[:new_member] = User.find(project_membership.user_id).login
  end
  
  def membership_notification(project_membership, new_member)
    setup_email(project_membership, new_member)
  end
  
  def invitation_notification(project_membership)
    recipient = User.find_by_id(project_membership.user_id)
    setup_email(project_membership, recipient)
    @body[:recipient] = recipient
  end
  
     
  protected
    def setup_email(project_membership, recipient)
      project = project_membership.project
      @recipients  = recipient.email
      @from        = "noreply@computer-beatz.net"
      @subject     = "[computer-beatz] Project " + h(project.name)
      @sent_on     = Time.now
      
      @body[:project] = project
    end

end
