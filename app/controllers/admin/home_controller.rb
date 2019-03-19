class Admin::HomeController < ApplicationController
  layout 'admin'
  
  before_filter :check_administrator_role
  
  def index
    @labels_count = Label.count
    @artists_count = Artist.count
    @tracks_count = Track.count
    @user_count = User.count  
  end

end
