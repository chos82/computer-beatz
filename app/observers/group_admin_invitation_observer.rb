class GroupAdminInvitationObserver < ActiveRecord::Observer
  
  def after_save(invitation)
    GroupAdminInvitationMailer.deliver_notification(invitation) if invitation.reciever.invitation_notify
  end
  
  def after_destroy(invitation)
    GroupAdminInvitationMailer.deliver_decline(invitation) if invitation.sender.invitation_notify
  end
  
end
