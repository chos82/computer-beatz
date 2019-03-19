class NewsMessageMailer < ActionMailer::Base
  
  #self.delivery_method = :activerecord

  def notification(message, recipient)
    setup_email(message, recipient)
    
    topic = message.topic
    
    @body[:url] = "http://#{SITE_URL}/groups/#{topic.group_id}"
    
    @body[:group] = topic.group
    
    @body[:member] = Member.find(:first, :conditions => ["user_id = ? AND group_id = ?", recipient.id, topic.group_id])
    
  end
  
     
  protected
    def setup_email(message, recipient)
      @recipients  = recipient.email
      @from        = "noreply@computer-beatz.net"
      @subject     = "[computer-beatz] Group " + h(message.topic.group.title) + " has news"
      @sent_on     = Time.now
    end
  
end