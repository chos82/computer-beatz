class MessageMailer < ActionMailer::Base

  #self.delivery_method = :activerecord

  def notification(message)
    sender = message.sender.login
    @recipients  = message.reciever.email
    @from        = "noreply@computer-beatz.net"
    @subject     = "[computer-beatz] #{sender} sent you a message"
    @sent_on     = Time.now
    @body[:sender] = sender
    
    @body[:reciever] = message.reciever
  end
  
end
