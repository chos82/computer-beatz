class FriendshipMailer < ActionMailer::Base
  
  #self.delivery_method = :activerecord

  def notification(friendship)    
    setup_email(friendship)
    @subject     = "[computer-beatz] #{@sender.login} wants to become your friend"
  end
  
  def approved_notification(friendship)    
    setup_email(friendship)
    @subject     = "[computer-beatz] You are now a friend of #{@sender.login}"
  end
  
  def destroyed_notification(friendship)    
    setup_email(friendship)
    @subject     = "[computer-beatz] #{@sender.login} quitted friendship with you"
  end
  
  def declined_notification(friendship)    
    setup_email(friendship)
    @subject     = "[computer-beatz] #{@sender.login} declined your friendship request"
  end
  
  
  private
  
  def setup_email(friendship)
    @sender = User.find(:first, :conditions => ['id = ?', friendship.user_id])
    @recipient = User.find(:first, :conditions => ['id = ?', friendship.friend_id])
    @recipients  = @recipient.email
    @from        = "noreply@computer-beatz.net"
    @sent_on     = Time.now
    @body[:sender] = @sender
    @body[:recipient] = @recipient
  end
    
end
