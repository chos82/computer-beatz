class GroupInvitationObserver < ActiveRecord::Observer
  
  def after_save(invitation)
    GroupInvitationMailer.deliver_notification(invitation) if invitation.reciever.invitation_notify
  end
  
end
