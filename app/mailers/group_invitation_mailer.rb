class GroupInvitationMailer < ActionMailer::Base

  #self.delivery_method = :activerecord

  def notification(invitation)
    @recipients  = invitation.reciever.email
    @from        = "noreply@computer-beatz.net"
    @subject     = "[computer-beatz] You have been invited"
    @sent_on     = Time.now
    
    @body[:sender] = invitation.sender
    @body[:group] = invitation.group
    @body[:reciever] = invitation.reciever
  end


end
