class SimilarController < ApplicationController
  require 'shared_controller.rb'
  include Shared
  
  layout 'music'
  
  def index
    @item = Music.find(params[:music_id])
    
    page = params[:page] ? params[:page] : 1
    
    @similars = @item.find_related_tags_for Music
    @similars.delete @item
    @similars = @similars[0...15]
      
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This item isn`t in the databse. It might have been removed."
        redirect_to :controller => 'music'
  end
  
end
