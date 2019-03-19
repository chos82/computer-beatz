module GroupsHelper
  def echo_group_status(group)
    if group.locked
      '<span title="You have to request to join">' +
      'locked</span>'
    else
      '<span title="Everyboby can join">' +
      'open</span>'
    end
  end
  
  def show_group?(group)
    return true if group.public
    if current_user
       if current_user.is_member?(group)
         return true
       end
   end
   return false
 end
 
end
