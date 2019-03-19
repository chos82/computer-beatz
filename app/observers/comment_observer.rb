class CommentObserver < ActiveRecord::Observer
  
 def after_save(comment)
   return if( comment.commentable_type != 'Project' && comment.commentable_type != 'Release' )
   
   if comment.commentable_type == 'Project'
     members = User.find( :all, :include => 'project_memberships',
                        :conditions => ['project_memberships.project_id = ?', comment.commentable_id] )
     members.each{|m|
       if m.id != comment.user_id
         CommentMailer.deliver_project_comment_notification m, comment
       end
     }
    elsif
      release = Release.find(comment.commentable_id)
      members = User.find(:all, :include => [:project_memberships], :conditions => ['project_memberships.project_id = ?', release.project_id])
      members.each{|m|
       if m.id != comment.user_id
         CommentMailer.deliver_release_comment_notification m, comment
       end
      }
    end
 end

end
