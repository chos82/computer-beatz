class ProjectMembershipObserver < ActiveRecord::Observer
  
  def after_destroy(project_membership)
    
    recipients = User.find(:all,
                           :include => ['project_memberships'],
                           :conditions => ["project_memberships.project_id = ? AND project_memberships.status = 'active'", project_membership.project_id])
    
    for recipient in recipients do
      ProjectMembershipMailer.deliver_declined_notification(project_membership, recipient)
    end
    
  end
  
  def after_save(project_membership)
    if project_membership.status == 'active'
      members = User.find(:all,
                          :include => ['project_memberships'],
                          :conditions => ["project_memberships.project_id = ? AND project_memberships.status = 'active' AND NOT user_id = ?", project_membership.project_id, project_membership.user_id])
      new_member = User.find(project_membership.user_id)
      for recipient in members do
        ProjectMembershipMailer.deliver_new_member_notification(project_membership, recipient)
      end
      ProjectMembershipMailer.deliver_membership_notification(project_membership, new_member) unless members.empty?
    elsif project_membership.status == 'invited'
      ProjectMembershipMailer.deliver_invitation_notification(project_membership)
    end
  end
  
end
