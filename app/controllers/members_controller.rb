class MembersController < ApplicationController
  before_filter :login_required, :except => [:index]
  
  layout 'groups'
  
  require 'shared_controller.rb'
  include Shared
  
  before_filter :find_group
  
  def index
    @page_title = "Members of #{h @group.title}"
    @member = Member.find(:first, :conditions => ["group_id = ? AND user_id = ?", @group.id, current_user.id]) if current_user
    if params[:order] == 'login'
      @members = User.paginate(:page => params[:page],
                               :include => ['members'],
                               :conditions => ["members.group_id = ? AND members.status = 'active'", @group.id],
                               :order => "users.last_login DESC, users.login")
    elsif params[:order] == 'messages'
      @members = User.paginate(:page => params[:page],
                               :include => ['members'],
                               :conditions => ["members.group_id = ? AND members.status = 'active'", @group.id],
                               :order => "members.no_messages DESC, users.login")
    else
      @members = User.paginate(:page => params[:page],
                               :include => ['members'],
                               :conditions => ["members.group_id = ? AND members.status = 'active'", @group.id],
                               :order => "users.login ASC")
    end  
    
    set_page_counts( Member.count(:conditions => ["group_id = ? AND status = 'active'", @group.id]), Member::per_page )
    
    #@member = Member.find(:first, :conditions => ["group_id = ? AND user_id = ?", @group.id, current_user.id]) if current_user
  end
  
  def new
    redirect_to users_path if current_user.declined?(@group)
    @page_title = "Become a member of #{@group.title}"
    @member = Member.new
    if @group.locked && !current_user.membership_pending?(@group)
      flash[:notice] = "This is a locked group. To join, you have to request the group admin first - use the button below to do so."
    end
  end
  
  def create
    unless @group.locked
      ActiveRecord::Base.transaction do
        @group.users << current_user
        if @group.save
          flash[:notice] = "You are now a member of this group."
        else
          render :action => 'new'
        end
      end
    else
      unless current_user.declined?(@group)
        @member = Member.new(:group_id => @group.id,
                             :user_id => current_user.id,
                             :status => 'pending',
                             :was_activated => false)
        if @member.save
          flash[:notice] = "The group admin has been informed about your interest to join the group."
        else
          render :action => 'new'
        end
      else
        redirect_to groups_path
      end
    end
    
    redirect_to group_path(@group)
  end
  
  def edit
    @member = Member.find(params[:id])
  end
  
  def update
    @member = Member.find(params[:id])
    if @member.user_id == current_user.id
      if @member.update_attributes(params[:member])
        flash[:notice] = "Membership has been updated."
        redirect_to group_path(@group)
      else
        render :action => 'edit'
      end
    else
      redirect_to groups_path
    end
    rescue ActiveRecord::RecordNotFound
        flash[:error] = "There is an error with the provided ID."
        redirect_to :action => 'index'
  end
  
  def pending
    if @group.admin == current_user
      @members = User.paginate(:page => params[:page],
                               :include => ['members'],
                               :conditions => ["members.group_id = ? AND members.status = 'pending'", @group.id],
                               :order => "members.created_at DESC")
    
      set_page_counts( Member.count(:conditions => ["members.group_id = ? AND members.status = 'pending'", @group.id]), Member::per_page )
    else
      redirect_to groups_path
    end
  end
  
  def approve
    if @group.admin == current_user
      @membership = Member.find(params[:id])
      @membership.status = 'active'
      if @membership.save
        flash[:notice] = "User has been activated."
        redirect_to pending_group_members_path(@group)
      else
        render :action => 'approve'
      end
    else
      redirect_to groups_path
    end
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This member isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def decline
    if @group.admin == current_user
      @membership = Member.find(params[:id])
      @membership.status = 'declined'
      if @membership.save
        flash[:notice] = "User has been declined."
        redirect_to pending_group_members_path(@group)
      else
        render :action => 'decline'
      end
    else
      redirect_to groups_path
    end
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This member isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def cancel
    if @group.admin == current_user
      @membership = Member.find(params[:id])
      unless @membership.user == @group.admin
        @membership.status = 'canceled'
        if @membership.save
          flash[:notice] = "User`s memebership in your group has been canceled."
          redirect_to pending_group_members_path(@group)
        else
          render :action => 'cancel'
        end
      end
    else
      redirect_to groups_path
    end
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This member isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  
  
  private
  
  def find_group
    group_id = params[:group_id]
    return(redirect_to(groups_url)) unless group_id
    @group = Group.find(group_id)
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This group isn`t in the databse. It might have been removed."
        redirect_to groups_path
  end
  
end
