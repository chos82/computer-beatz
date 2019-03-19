class MemberObserver < ActiveRecord::Observer
  
  def after_save(member)
    if member.user.invitation_notify
      MemberMailer.deliver_join_request(member) if member.pending? && member.group.join_requests
      if member.recently_activated?
        MemberMailer.deliver_approved(member)
        member.was_activated = true
        member.save
      end
      MemberMailer.deliver_declined(member) if member.declined?
    end
  end
  
end
