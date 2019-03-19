class FriendshipObserver < ActiveRecord::Observer
  
  def after_save(friendship)
    user = User.find(:first, :conditions => ['id = ?', friendship.user_id])
    if user.invitation_notify
      if Friendship.find(:first, :conditions => ['user_id = ? AND friend_id = ?', friendship.friend_id, friendship.user_id])
        FriendshipMailer.deliver_approved_notification(friendship) # mutual friendship now
      else
        FriendshipMailer.deliver_notification(friendship) # a request to become frineds
      end
    end
  end
  
  def after_destroy(friendship)
    user = User.find(:first, :conditions => ['id = ?', friendship.user_id])
    if user.invitation_notify
      if friendship.is_declined
         FriendshipMailer.deliver_declined_notification(friendship)
      else
        FriendshipMailer.deliver_destroyed_notification(friendship)
      end 
    end
  end
  
end
