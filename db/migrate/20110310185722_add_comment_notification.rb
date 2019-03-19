class AddCommentNotification < ActiveRecord::Migration

  def self.up
    add_column :project_memberships, :comment_notification, :boolean, :default => true
  end
 
  def self.down
    remove_column :project_memberships, :comment_notification
  end

end
