class PreviewController < ApplicationController
  before_filter :login_required
  
  def redcloth
      @text = params[:text]
      render :partial => 'redcloth' , :layout=>false
  end
  
  def hide_preview_500
    respond_to do |format|
      format.js
    end 
  end
  
  def hide_preview_3000
    respond_to do |format|
      format.js
    end 
  end
  
  def hide_preview_no_limit
    respond_to do |format|
      format.js
    end 
  end
  
  def show_preview_500
    @text = params[:text]
    respond_to do |format|
      format.js
    end 
  end
  
  def show_preview_3000
    @text = params[:text]
    respond_to do |format|
      format.js
    end 
  end
  
  def show_preview_no_limit
    @text = params[:text]
    respond_to do |format|
      format.js
    end 
  end
  
end