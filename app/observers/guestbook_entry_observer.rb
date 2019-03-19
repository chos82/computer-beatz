class GuestbookEntryObserver < ActiveRecord::Observer
  
  def after_save(entry)
    GuestbookMailer.deliver_notification(entry) if entry.gb_reciever.guestbook_notify && entry.gb_reciever != entry.gb_sender
  end
  
end
