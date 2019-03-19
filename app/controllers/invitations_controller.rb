class InvitationsController < ApplicationController
  require 'shared_controller.rb'
  include Shared
  require 'exceptions.rb'
  include Exceptions
  
  layout 'users'
  
  before_filter :login_required
  
  def index
    @page_title = "Your invitations"
    @invitations = GroupInvitation.find(:all,
                                   :include => ['sender', 'group'],
                                     :conditions => ["reciever = ?", current_user.id],
                                     :order => ["created_at DESC"],
                                     :limit => 10)
    @show_more_i = GroupInvitation.count(:all, :conditions => ["reciever = ?", current_user.id]) > 10
                                        
    @admin_invitations = GroupAdminInvitation.find(:all,
                                                     :include => ['sender', 'group'],
                                                     :conditions => ["reciever = ?", current_user.id],
                                                     :order => ["created_at DESC"],
                                                     :limit => 3)
    @show_more_ai = GroupAdminInvitation.count(:all, :conditions => ["reciever = ?", current_user.id]) > 3
                                                     
    @project_invitations = ProjectMembership.find(:all,
                                           :conditions => ["user_id = ? AND status = 'invited'", current_user.id],
                                           :order => ["created_at DESC"])
    
    @fans = current_user.fans_of_me
    @show_more_fans = @fans.length > 10
    @fans = @fans[0..10]
  end
  
  def groups
    @page_title = "Invitations to groups"
    @invitations = GroupInvitation.find(:all,
                                    :include => ['sender', 'group'],
                                     :conditions => ["reciever = ?", current_user.id],
                                     :order => ["created_at DESC"])
  end
  
  def administration
    @page_title = "Invitations to become admin of a group"
    @admin_invitations = GroupAdminInvitation.find(:all,
                                                     :include => ['sender', 'group'],
                                                     :conditions => ["reciever = ?", current_user.id],
                                                     :order => ["created_at DESC"])
  end
  
  def friendship
    @page_title = "Requested friendships"
    @fans = current_user.fans_of_me
  end
    
  def new
    c_user = current_user
    @user = User.find(params[:user_id])
    invited = Group.find(:all,
                         :include => ["invitations"],
                         :conditions => ["invitations.sender = ? AND invitations.reciever = ?", c_user.id, @user.id])
    my_groups = Group.find(:all,
                         :include => ['members'],
                         :conditions => ["( NOT groups.locked = 1 OR groups.admin = ? ) AND members.user_id = ?", c_user.id, c_user.id],
                         :order => ["members.created_at DESC"])
    user_groups = Group.find(:all,
                              :include => ['members'],
                              :conditions => ["members.user_id = ?", @user.id])                     
    @groups = (my_groups - user_groups -invited)
    set_page_counts( @groups.length, Group::per_page )
    @groups = @groups.paginate(:page => params[:page])
  end
  
  def create
    user_id = params[:user_id]
    return(redirect_to(users_url)) unless user_id
    @user = User.find(user_id)
    
    @group = Group.find(params[:group_id])
    invited = GroupInvitation.find(:all, :conditions => ["sender = ? AND reciever = ? AND group_id = ?", current_user.id, @user.id, @group.id])
    if (!@group.locked || @group.admin == current_user) && !@user.is_member?(@group) && invited.empty?
    @invitation = GroupInvitation.new()
    @invitation.group = @group
    @invitation.sender = current_user
    @invitation.reciever = @user

      respond_to do |format|
        if @invitation.save
          flash[:notice] = 'Invitation was successfully sent.'
          format.html { redirect_to new_user_invitation_path(@user) }
          format.xml  { render :xml => @user, :status => :created, :location => @user }
        else
          flash[:error] = 'There was a problem to crate the invitation, sorry.'
          format.html { redirect_to new_user_invitation_path(@user) }
          format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
        end
      end
    else
      redirect_to users_url
    end
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This item isn`t in the databse. It might have been removed."
        redirect_to users_path
  end
  
  def accept
    @invitation = GroupInvitation.find(params[:id])
    raise AttemptToFakePrivilege.new(@invitation) unless @invitation.reciever == current_user
    group = @invitation.group
    group.users << current_user
      ActiveRecord::Base.transaction do
        if group.save
          GroupInvitation.delete_all(["reciever = ? AND group_id = ?", @invitation.reciever, @invitation.group_id])
          flash[:notice] = "You accepted the invitation to the group. You are now a group member."
          redirect_to myinvitations_path(current_user)
        else
          flash[:error] = "There was a probem changing your status, sorry."
          render :action => 'new'
        end
      end
    
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "The invitation isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
    rescue AttemptToFakePrivilege
       logger.info("[AttemptToFakePrivilege] #{current_user.login} (ID: #{current_user.id}) tryed to access private information of #{@invitation.reciever.login} (ID: #{@invitation.reciever.id}).")
       redirect_to users_path
  end
  
  def destroy
    @invitation = GroupInvitation.find(params[:id])
    raise AttemptToFakePrivilege.new(@invitation) unless @invitation.reciever == current_user
      @invitation.destroy

      respond_to do |format|
        format.html { redirect_to(myinvitations_path(current_user)) }
        format.xml  { head :ok }
      end
      
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "The invitation isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
    rescue AttemptToFakePrivilege
       logger.info("[AttemptToFakePrivilege] #{current_user.login} (ID: #{current_user.id}) tryed to access private information of #{@invitation.reciever.login} (ID: #{@invitation.reciever.id}).")
       redirect_to users_path
  end
  
end
