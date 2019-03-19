class MemberMailer < ActionMailer::Base

  #self.delivery_method = :activerecord

  def join_request(member)
    setup_email(member)
    
    @subject += "#{member.user.login} requests access to #{@group.title}"
    
    @body[:pending_url] = "http://#{SITE_URL}/groups/#{@group.id}/members/pending"
    
  end

  def approved(member)
    setup_email(member)
    
    @subject += "Your request to access #{@group.title} was approved"
    
  end
  
  def declined(member)
    setup_email(member)
    
    @subject += "Your request to access #{@group.title} was declined"
    
  end
    
  protected
    def setup_email(member)
      @recipients  = "#{member.user.email}"
      @from        = "noreply@computer-beatz.net"
      @subject     = "[computer-beatz] "
      @sent_on     = Time.now
      @body[:member] = member.user
      @group = member.group
      @body[:group] = @group
    end
  
end