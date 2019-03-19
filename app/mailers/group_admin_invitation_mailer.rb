class GroupAdminInvitationMailer < ActionMailer::Base

  #self.delivery_method = :activerecord

  def notification(invitation)
    @recipients  = invitation.reciever.email
    
    setup_body invitation
  end
  
  def decline(invitation)
    @recipients  = invitation.sender.email

    setup_body invitation
  end
  
  def accept(invitation)
    @recipients  = invitation.sender.email

    setup_body invitation
  end
  
  private
  
  def setup_body(invitation)
    @from        = "noreply@computer-beatz.net"
    @subject     = "[computer-beatz] You have been invited"
    @sent_on     = Time.now
    @body[:sender] = invitation.sender
    @body[:group] = invitation.group
    @body[:reciever] = invitation.reciever
  end

end
