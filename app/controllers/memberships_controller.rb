class MembershipsController < ApplicationController
  require 'shared_controller.rb'
  include Shared
  require 'exceptions.rb'
  include Exceptions
  
  layout 'users'
  
  def index
    user_id = params[:user_id]
    return(redirect_to(users_url)) unless user_id
    @user = User.find(user_id)
    unless @user.enabled
      render :partial => 'accout_disabled', :layout => true
    else
      @page_title = "Groups #{h @user.login} is member"
      if @user == current_user
        redirect_to mygroups_path(@user)
      end
      redirect_to forbidden_users_path unless show_page?(@user, @user.tagged_privacy)
      
      do_index(@user)
    end
    
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This user isn`t in the databse. It might have been removed."
        redirect_to user_path
  end
  
  def mygroups
    @page_title = "Your group memberships"
    user = User.find(params[:id])
    unless user.enabled
      render :partial => 'accout_disabled', :layout => true
    else
      unless user == current_user
        redirect_to user_memberships_path(user)
      else
        do_index(current_user)
      end
    end
  end
  
  private
  
  def do_index(user)
    @groups = Group.paginate(:page => params[:page], :include => 'members', :conditions => ["members.user_id = ? AND members.status = 'active'", user.id], :order => 'members.created_at DESC')
    
    set_page_counts( Group.count(:all, :include => 'members', :conditions => ["members.user_id = ? AND members.status = 'active'", user.id]), Group::per_page )
  end
  
end

