class Admin::LabelsController < ApplicationController
  layout 'admin'
  
  before_filter :check_administrator_role
  
  def show
    @label = Label.find(params[:id])
    @report = Report.find(:first, :conditions => ["reportable_id = ?", @label.id])
    @user = User.find(:first, :conditions => ["id = ?", @report.user_id])
  end
  
  def edit
    @label = Label.find(params[:id])
  end
  
  def update
   @label = Label.find(params[:id])
    Report.delete_all(["reportable_id = ?", @label.id])
    if @label.update_attributes(params[:label])
      flash[:notice] = 'Artist was successfully updated.'
      redirect_to admin_music_index_path
    else
      flash[:notice] = 'Unprocessable entry.'
      redirect_to admin_music_index_path
    end
  end

  
end
