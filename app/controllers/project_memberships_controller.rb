class ProjectMembershipsController < ApplicationController
  layout 'application'
  
  require 'exceptions.rb'
  include Exceptions
  
  def accept
    @membership = ProjectMembership.find(params[:id])
    raise AttemptToFakePrivilege.new(@membership) unless @membership.user == current_user
    
    @membership.status = 'active'
    if @membership.save
      flash[:notice] = "You are now a member of the project <b>#{@membership.project.name}</b>"
      redirect_to myinvitations_path(current_user)
    end
    
    rescue AttemptToFakePrivilege
      logger.info("[AttemptToFakePrivilege] #{current_user.login} (ID: #{current_user.id}) tryed to become a member of #{@membership.project.name}.")
      redirect_to projects_path
    rescue ActiveRecord::RecordNotFound
      flash[:notice] = "This item might have been removed."
      redirect_to :action => 'index'
  end
  
  def destroy
    @membership = ProjectMembership.find(params[:id])
    
    @membership.destroy
    
    redirect_to myinvitations_path(current_user)
    
    rescue ActiveRecord::RecordNotFound
      flash[:notice] = "This project isn`t in the databse. It might have been removed."
      redirect_to :action => 'index'
  end
  
end