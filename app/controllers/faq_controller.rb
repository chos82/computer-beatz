class FaqController < ApplicationController
  
  layout 'application'
  
  def index
    @page_title = "FAQ - Frequently asked Questions"
  end
  
end
