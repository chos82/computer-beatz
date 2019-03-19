class GuestbookMailer < ActionMailer::Base
  
  #self.delivery_method = :activerecord

  def notification(entry)
    @recipients  = entry.gb_reciever.email
    @from        = "noreply@computer-beatz.net"
    @subject     = "[computer-beatz] you have a new guestbook entry"
    @sent_on     = Time.now
    
    @body[:reciever] = entry.gb_reciever
  end

end
