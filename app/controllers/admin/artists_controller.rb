class Admin::ArtistsController < ApplicationController
  layout 'admin'
  
  before_filter :check_administrator_role
  
  def show
    @artist = Artist.find(params[:id])
    @report = Report.find(:first, :conditions => ["reportable_id = ?", @artist.id])
    @user = User.find(:first, :conditions => ["id = ?", @report.user_id])
  end
  
  def edit
    @artist = Artist.find(params[:id])
  end

  def update
    @artist = Artist.find(params[:id])
    Report.delete_all(["reportable_id = ?", @artist.id])
    if @artist.update_attributes(params[:artist])
      flash[:notice] = 'Artist was successfully updated.'
      redirect_to admin_music_index_path
    else
      flash[:notice] = 'Unprocessable entry.'
      redirect_to admin_music_index_path
    end
  end

end
