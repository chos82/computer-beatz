class Admin::AlbumsController < ApplicationController
  layout 'admin'
  
  before_filter :check_administrator_role
  
  def show
    @album = Album.find(params[:id])
    @report = Report.find(:first, :conditions => ["reportable_id = ?", @album.id])
    @user = User.find(:first, :conditions => ["id = ?", @report.user_id])
  end
  
  def edit
    @album = Album.find(params[:id])
  end
  
  def update
   @album = Album.find(params[:id])
    Report.delete_all(["reportable_id = ?", @album.id])
    if @album.update_attributes(params[:label])
      flash[:notice] = 'Album was successfully updated.'
      redirect_to admin_music_index_path
    else
      flash[:notice] = 'Unprocessable entry.'
      redirect_to admin_music_index_path
    end
  end
  
  def remove_artist
    @album = Album.find(params[:id])
    @album.artist_id = nil
    Report.delete_all(["reportable_id = ?", @album.id])
    if @album.save
      falsh[:notice] = "Artist removed."
      redirect_to admin_music_index_path
    else
      flash[:notice] = 'Unprocessable entry.'
      redirect_to admin_music_index_path
    end
  end
  
  def remove_label
    @album = Album.find(params[:id])
    @album.label_id = nil
    Report.delete_all(["reportable_id = ?", @album.id])
    if @album.save
      flash[:notice] = "Label removed."
      redirect_to admin_music_index_path
    else
      flash[:notice] = 'Unprocessable entry.'
      redirect_to admin_music_index_path
    end
  end
  
end
