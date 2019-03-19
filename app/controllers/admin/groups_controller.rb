class Admin::GroupsController < ApplicationController
  
  layout 'admin'
  
  before_filter :check_administrator_role
  
  def index
    @groups = Group.paginate(:all, :page => params[:page], :order => 'title')
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @groups }
    end
  end
  
  def destroy
    @group = Group.find(params[:id])
    if @group.destroy
      flash[:notice] = "Group was removed from DB"
    else
      flash[:error] = "There was a problem removing this group."
    end
    redirect_to :action => 'index'
  end
  
  def search
    @groups = Group.paginate(:all, :page => params[:page], :conditions => ["title LIKE ?", '%' + params[:search][:title] + '%'])
    render :action => 'index'
  end
  
end
