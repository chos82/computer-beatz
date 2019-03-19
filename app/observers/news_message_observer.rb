class NewsMessageObserver < ActiveRecord::Observer
  require 'mass_mailing.rb'
  include MassMailer
  
  def after_save(message)
    
    recipients = User.find(:all,
                           :include => ['members'],
                           :conditions => ["members.group_id = ? AND members.status = 'active' AND members.news_notification = 1 AND was_activated = 1 AND enabled = 1", message.topic.group_id])
    
    current = User.find(:first, :include => ['news_messages'],
                             :conditions => ["news_messages.id = ?", message.id])
    foo = [current]
    recipients -= foo
    for recipient in recipients do
      NewsMessageMailer.deliver_notification(message, recipient)
    end
    
  end
  
end
