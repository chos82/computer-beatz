class NewsletterObserver < ActiveRecord::Observer
  
  def after_save(newsletter)
    recipients = User.find(:all, :conditions => ['newsletter = ?', true])
    recipients.each do |recipient|
      NewsletterMailer.deliver_newsletter(newsletter, recipient)
    end
  end
  
end
