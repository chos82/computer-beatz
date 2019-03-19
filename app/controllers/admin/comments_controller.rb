class Admin::CommentsController < ApplicationController
  layout 'admin'
  
  before_filter :check_administrator_role

  def show
    @comment = Comment.find params[:id]
    @item = Music.find(:first, :conditions => ['music.id = ?', @comment.commentable_id])
  end
  
  def index
    @reports = Report.find(:all, :include => 'reportable', :conditions => ["reportable_type = 'Comment'"])
  end
  
  def destroy
    @comment = Comment.find(params[:id])
    @comment.destroy
    
    redirect_to admin_comments_path
  end
  
  def set_valid
    @comment = Comment.find(params[:id])
    Report.destroy_all(["reportable_type = 'Comment' AND reportable_id = ?", @comment.id])
    redirect_to :action => :index
  end
  
end
