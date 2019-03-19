class ReleaseMailer < ActionMailer::Base
  
  #self.delivery_method = :activerecord

  def uploaded_notification
    subject    '[computer-beatz] Release uploaded'
    recipients 'ch.ossner@googlemail.com'
    from       'noreply@computer-beatz.net'
    sent_on    Time.now
  end

  def released_notification(release, recipient)
    subject    "[computer-beatz] #{h release.project.name} - #{release.name} released"
    @recipients  = recipient.email
    from       'noreply@computer-beatz.net'
    sent_on    Time.now
    
    @body[:release] = release
  end
  
  def declined_notification(release, recipient, message = nil)
    subject    "[computer-beatz] #{h release.project.name} - #{release.name} has been declined"
    @recipients = recipient.email
    from       'noreply@computer-beatz.net'
    sent_on    Time.now
    
    @body[:release] = release
    @body[:message] = message
  end

end
