class CommentMailer < ActionMailer::Base
  
  def project_comment_notification(recipient, comment)
    project = Project.find(comment.commentable_id)
    @recipients  = recipient.email
    @from        = "noreply@computer-beatz.net"
    @subject     = "[computer-beatz] Project " + h(project.name) + " has a new comment"
    @sent_on     = Time.now
    
    @body[:project] = project
  end
  
  def release_comment_notification(recipient, comment)
    release = Release.find(comment.commentable_id)
    @recipients  = recipient.email
    @from        = "noreply@computer-beatz.net"
    @subject     = "[computer-beatz] Release " + h(release.name) + " has a new comment"
    @sent_on     = Time.now
    
    @body[:release] = release
    @body[:project] = release.project
  end

end
