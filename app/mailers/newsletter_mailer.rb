class NewsletterMailer < ActionMailer::Base
  
  def newsletter(newsletter, recipient)
    setup_email(newsletter, recipient)
    
    @body[:text] = newsletter.text
    
  end
  
     
  protected
    def setup_email(newsletter, recipient)
      @recipients  = recipient.email
      @from        = "noreply@computer-beatz.net"
      @subject     = "[computer-beatz Newsletter] " + h(newsletter.subject)
      @sent_on     = Time.now
    end

end
