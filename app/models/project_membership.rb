class ProjectMembership < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :project
  
  validates_inclusion_of :status,
    :in => %w{ active invited },
    :message => "is not valid."
    
  def self.comment_notifications?(user, project)
    this = self.find(:first, :conditions => ["user_id = ? AND project_id = ?", user.id, project.id])
    if this.comment_notification
      true
    else
      false
    end
  end
  
end
