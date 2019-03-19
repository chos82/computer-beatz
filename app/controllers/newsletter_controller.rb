class NewsletterController < ApplicationController
  require 'shared_controller.rb'
  include Shared
  
  def index
    @page_title = "Newsletter"
    @newsletters = Newsletter.paginate( :page => params[:page], :order => 'created_at DESC')
    
    set_page_counts( Newsletter.count(:all), Newsletter::per_page )
  end
  
  def show
    @newsletter = Newsletter.find(params[:id])
    @page_title = "Newsletter from #{@newsletter.created_at.to_s(:month_year)}"
  end
  
end
