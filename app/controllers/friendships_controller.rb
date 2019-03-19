class FriendshipsController < ApplicationController
  require 'exceptions.rb'
  include Exceptions
  
  def index
    @user = User.find(params[:user_id])
    unless @user.enabled
      render :partial => 'accout_disabled', :layout => true
    else
      @page_title = "Friends of #{h @user.login}"
      if @user == current_user
        redirect_to myfriends_path(current_user)
      end
      redirect_to forbidden_users_path unless show_page?(@user, @user.friendships_privacy)
      
      @friends = @user.mutual_friends.paginate( :page => params[:page] )
    end
  end
  
  def myfriends
    @page_title = "Your friends"
    @user = User.find(params[:id])
    unless @user.enabled
      render :partial => 'accout_disabled', :layout => true
    else
      unless @user == current_user
        redirect_to user_friendships_path(@user)
      else
        @friends = current_user.mutual_friends.paginate( :page => params[:page] )
      end
    end
  end
  
  def requested
    @page_title = "Friendships you requested"
    @user = User.find(params[:user_id])
    unless @user.enabled
      render :partial => 'accout_disabled', :layout => true
    else
      raise AttemptToFakeUser.new(@user) unless @user == current_user
      
      @requested = @user.is_a_fan_of
    end 
    rescue ActiveRecord::RecordNotFound
      flash[:notice] = "This user isn`t in the databse. It might have been removed."
      redirect_to users_path
    rescue AttemptToFakeUser
      logger.info("[AttemptToFakeUser] #{current_user.login} (ID: #{current_user.id}) tryed to access private information of #{@user.login} (ID: #{@user.id}).")
      redirect_to users_path
  end
  
  def new
    @user = User.find(params[:user_id])
    @make_friend = true
    respond_to do |format|
      format.html{redirect_to user_path(@user)}
    end 
    
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This user isn`t in the databse. It might have been removed."
        redirect_to users_path
  end
  
  def create
    @user  = User.find(params[:user_id])
    current_user.add_friend(@user) unless @user.is_friends_with? current_user
    flash[:notice] = "You requested to be a friend of this user.<br/>"+
                     "The friendship has to be approved by <b>#{@user.login}</b>"
    redirect_to user_path(@user)
    
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This user isn`t in the databse. It might have been removed."
        redirect_to users_path
  end
  
  def accept
      @user  = User.find(params[:id])
      cu = User.find params[:user_id]
      raise AttemptToFakeUser.new(@user) unless cu == current_user
      
      if @user.is_friends_with?(current_user) && !current_user.is_friends_with?(@user)
        current_user.add_friend(@user)
        flash[:notice] = "You are now a friend of <b>#{@user.login}</b>"
      end
    redirect_to myinvitations_path(current_user)
    
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This user isn`t in the databse. It might have been removed."
        redirect_to users_path
    rescue AttemptToFakeUser
      logger.info("[AttemptToFakeUser] #{current_user.login} (ID: #{current_user.id}) tryed to access private information of #{@user.login} (ID: #{@user.id}).")
      redirect_to user_path(@user)
  end
  
  def accepting
      @user  = User.find(params[:id])
      friend = User.find params[:user_id]
      raise AttemptToFakeUser.new(@user) unless @user == current_user
      
      if friend.is_friends_with?(@user) && !@user.is_friends_with?(friend)
        @user.add_friend(friend)
        flash[:notice] = "You are now a friend of <b>#{friend.login}</b>"
      end
    redirect_to user_path(friend)
    
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This user isn`t in the databse. It might have been removed."
        redirect_to users_path
    rescue AttemptToFakeUser
      logger.info("[AttemptToFakeUser] #{current_user.login} (ID: #{current_user.id}) tryed to access private information of #{@user.login} (ID: #{@user.id}).")
      redirect_to user_path(@user)
  end
  
  def decline
    user  = User.find(params[:user_id])
    friend = User.find params[:id]
    raise AttemptToFakeUser.new(user) unless user == current_user
    
    if friend.is_friends_with? user
      user.decline_friendship_with friend
    end
    redirect_to user_invitations_path(user)
    
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This user isn`t in the databse. It might have been removed."
        redirect_to users_path
    rescue AttemptToFakeUser
      logger.info("[AttemptToFakeUser] #{current_user.login} (ID: #{current_user.id}) tryed to access private information of #{@user.login} (ID: #{@user.id}).")
      redirect_to users_path
  end
  
  def destroy
    user  = User.find(params[:user_id])
    friend = User.find(params[:id])
    raise AttemptToFakeUser.new(suser) unless user == current_user
    
    user.destroy_friendship_with friend
    
    redirect_to user_path(user)
    
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This user isn`t in the databse. It might have been removed."
        redirect_to users_path
    rescue AttemptToFakeUser
      logger.info("[AttemptToFakeUser] #{current_user.login} (ID: #{current_user.id}) tryed to access private information of #{user.login} (ID: #{user.id}).")
      redirect_to users_path
  end
  
end
