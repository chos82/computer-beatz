class Admin::TracksController < ApplicationController
  layout 'admin'
  
  before_filter :check_administrator_role
  
  def show
    @track = Track.find(params[:id])
    @report = Report.find(:first, :conditions => ["reportable_id = ?", @track.id])
    @user = User.find(:first, :conditions => ["id = ?", @report.user_id])
  end
  
  def edit
    @track = Track.find(params[:id])
  end

  def update
    @track = Track.find(params[:id])
    Report.delete_all(["reportable_id = ?", @track.id])
    if @track.update_attributes(params[:track])
      flash[:notice] = 'Artist was successfully updated.'
      redirect_to admin_music_index_path
    else
      flash[:notice] = 'Unprocessable entry.'
      redirect_to admin_music_index_path
    end
  end
  
  def remove_artist
    @track = Track.find(params[:id])
    @track.artist_id = nil
    Report.delete_all(["reportable_id = ?", @track.id])
    if @track.save
      falsh[:notice] = "Artist removed."
      redirect_to admin_music_index_path
    else
      flash[:notice] = 'Unprocessable entry.'
      redirect_to admin_music_index_path
    end
  end
  
  def remove_label
    @track = Track.find(params[:id])
    @track.label_id = nil
    Report.delete_all(["reportable_id = ?", @track.id])
    if @track.save
      flash[:notice] = "Label removed."
      redirect_to admin_music_index_path
    else
      flash[:notice] = 'Unprocessable entry.'
      redirect_to admin_music_index_path
    end
  end
  
  def remove_album
    @track = Track.find(params[:id])
    @album = Album.find(params[:album])
    @track.albums.delete(@album)
    Report.delete_all(["reportable_id = ?", @track.id])
    if @track.save
      flash[:notice] = "Album removed."
      redirect_to admin_music_index_path
    else
      flash[:notice] = 'Unprocessable entry.'
      redirect_to admin_music_index_path
    end
  end
  
  def remove_video
    @track = Track.find(params[:id])
    @track.video = nil
     Report.delete_all(["reportable_id = ?", @track.id])
    if @track.save
      flash[:notice] = "Video removed."
      redirect_to admin_music_index_path
    else
      flash[:notice] = 'Unprocessable entry.'
      redirect_to admin_music_index_path
    end
  end

end
