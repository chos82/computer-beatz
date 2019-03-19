class InboxObserver < ActiveRecord::Observer
  
  def after_save(inbox)
    if inbox.updated_at == inbox.created_at && inbox.reciever.message_notify && inbox.reciever.enabled
      MessageMailer.deliver_notification(inbox)
    end
  end
  
end
