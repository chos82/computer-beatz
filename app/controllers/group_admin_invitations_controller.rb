class GroupAdminInvitationsController < ApplicationController
  before_filter :login_required
  
  layout 'users'
  require 'exceptions.rb'
  include Exceptions
  
  def accept
    @invitation = GroupAdminInvitation.find(params[:id])
    @user = User.find(params[:user_id])
    raise AttemptToFakePrivilege.new @invitation unless @invitation.reciever == @user && @user == current_user
      group = @invitation.group
      unless group.users.include? @user
        group.users << @user
      end
      group.admin = @user
      GroupAdminInvitationMailer.deliver_accept(@invitation) if @invitation.sender.invitation_notify
      if group.save
        GroupAdminInvitation.delete(params[:id])
        GroupInvitation.delete_all(["reciever = ? AND group = ?", @invitation.reciever, @invitation.group_id])
        flash[:notice] = "You accepted the invitation to the group. You are now a group member."
        redirect_to user_invitations_path(@user)
      else
        flash[:error] = "There was a probem changing your status, sorry."
        render :action => 'new'
      end
  
   rescue AttemptToFakePrivilege
       logger.info("[AttemptToFakePrivilege] #{current_user.login} (ID: #{current_user.id}) tryed to access private information of #{@invitation.reciever.login} (ID: #{@invitation.reciever.id}).")
       redirect_to users_path
  end
  
  def destroy
    @invitation = GroupAdminInvitation.find(params[:id])
    @user = User.find(params[:user_id])
    raise AttemptToFakePrivilege.new @invitation unless @invitation.reciever == @user && @user == current_user 
      @invitation.destroy

      respond_to do |format|
        format.html { redirect_to(users_invitations_path(@user)) }
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
