class Admin::NewsletterController < ApplicationController
  layout 'admin'
  
  before_filter :check_administrator_role
  
  def new
    @newsletter = Newsletter.new(params[:newsletter])
  end
  
  def create
    @newsletter = Newsletter.new(params[:newsletter])
    respond_to do |format|
      if @newsletter.save
        flash[:notice] = 'Newsletter was successfully created.'
        format.html { redirect_to(:action => "new") }
      else
        format.html { render :action => "new" }
      end
    end
  end
  
end
