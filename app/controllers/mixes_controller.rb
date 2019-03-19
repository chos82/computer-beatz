class MixesController < ApplicationController
  
  before_filter :login_required, :except => [:index, :show, :tags, :search, :search_results]
  before_filter :get_tags, :except => [:tags, :show]
  
  require 'shared_controller.rb'
  include Shared
  
  layout 'music'
  
  auto_complete_for :mix, :name
  
  def index
   @page_title = "Mixes"
   @order = params[:order]
    
    if @order == 'comments'
      @mixes  =  Mix.paginate( :page => params[:page],
                                :order => 'music.comments_count DESC, music.name',
                                :include => [:artist, :ratings])
    elsif @order == 'last_commented'
      @mixes  =  Mix.paginate( :page => params[:page],
                                :include => [:artist, :ratings, :comments],
                                :order => 'comments.created_at DESC, music.name')
    elsif @order == 'loves'
      @mixes  =  Mix.paginate( :page => params[:page],
                                :order => 'music.favourites_count DESC, music.name',
                                :include => [:artist, :ratings])
    elsif @order == 'rating'
      @mixes  =  Mix.paginate( :page => params[:page],
                                :include => [:artist, :ratings],
                                :group => 'music.id',
                                :order => 'AVG(ratings.rating) DESC')
    else
      @mixes  =  Mix.paginate( :page => params[:page],
                                :order => 'music.name',
                                :include => ['artist', 'ratings'])
    end  
    
    set_page_counts( Mix.count(:all), Music::per_page )
    
    respond_to do |format|
      format.html { render :action => 'index' }
      format.xml  { render :xml => @mixes }
    end
  end
  
  def tags
    @page_title = "Mix Tags"
    @tags = Music.tag_counts( :conditions => ["type = 'Mix'"] )
  end

  def show
      @mix= Mix.find(params[:id], :include => :tracks )
      @page_title = h(@mix.name)
      @page_title += ' by ' +h(@mix.artist.name) if @mix.artist
      @page_title += ', ' + @mix.release_date.year.to_s if @mix.release_date
      @tags = @mix.tag_counts(  :conditions => ["type = 'Mix'"]  )
      @rating_count = @mix.ratings.size
      @ur = Rating.find(:first, :conditions => [ "user_id = ? AND rateable_id = ? AND rateable_type ='Music'", current_user, params[:id] ]) if current_user
      @love = @mix.users.index( current_user ) if current_user
      @comments = Comment.paginate :page => params[:page],
                                  :include => ['report'],
                                  :conditions => ["commentable_id = ? AND commentable_type ='Music'", @mix.id],
                                  :order => 'created_at DESC'
      @comment = Comment.new

      respond_to do |format|
        format.html # show.html.erb
        format.xml  { render :xml => @mix }
    end
    rescue ActiveRecord::RecordNotFound
      flash[:notice] = "This mix isn`t in the databse. It might have been removed."
      redirect_to :action => 'index'
  end
  
  def tag
    @tag = params[:id]
    @page_title = "Tag #{h @tag} on Mixes"
    
    if params[:order] == 'name'
      tagged = Music.tagged_with( @tag, :on => :tags, :conditions => ["type = 'Mix'"] ).by_name
      @mixes = tagged.paginate( :page => params[:page] )
    elsif params[:order] == 'comments'
      tagged = Music.tagged_with( @tag, :on => :tags, :conditions => ["type = 'Mix'"] ).by_comments
      @mixes = tagged.paginate( :page => params[:page] )
    elsif params[:order] == 'last_commented'
      tagged = Music.tagged_with( @tag, :on => :tags, :conditions => ["type = 'Mix'"] ).by_comments_date
      @mixes = tagged.paginate( :page => params[:page] )
    elsif params[:order] == 'loves'
      tagged = Music.tagged_with( @tag, :on => :tags, :conditions => ["type = 'Mix'"] ).by_loves
      @mixes = tagged.paginate( :page => params[:page] )
    elsif params[:order] == 'rating'
      tagged = Music.tagged_with( @tag, :on => :tags, :conditions => ["type = 'Mix'"] ).by_rating
      @mixes = tagged.paginate( :page => params[:page] )
    else
      tagged = Music.tagged_with( @tag, :on => :tags, :conditions => ["type = 'Mix'"] ).by_date
      @mixes = tagged.paginate( :page => params[:page] )
    end
    
    set_page_counts( tagged.length, Music::per_page )
    
  end

  def new
    @page_title = "New Mix"
    @mix = Mix.new(params[:mix])
    @artist = Artist.find(params[:artist_id]) if params[:artist_id]
    @track = Track.find(params[:track_id]) if params[:track_id]

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @mix }
    end
  end
  
  def check_new
    @intended = params[:mix]
    unless @intended[:name].blank?
      equal = Mix.find(:first, :conditions => [ "name = ?", @intended[:name] ])
      if equal.blank?
        @similars = Mix.find(:all, :conditions => ["name like ?", '%' + @intended[:name] + '%'],
                             :order => 'name')
        create_new if @similars.empty?
      else
        notice = "This mix is already in the database.<br>"
        notice += "<br>You can add it to an <em>artist</em>." if equal.artist_id.nil?
        flash[:notice] = notice
        redirect_to :action => 'show', :id => equal.id
      end
    else
    redirect_to :action => 'new'
    end
  end
  
  def add_track
    @mix = Mix.find(params[:id])
    @track_listing = TrackListing.new
    @page_title = "Add a track to #{h @mix.name}"
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This mix isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def check_added_track
    @mix = Mix.find(params[:id])
    track = Track.find(:first, :conditions => ["name = ?", params[:track][:name]]) if params[:track][:name]
    unless track.nil?
        ActiveRecord::Base.transaction do
          track_listing = TrackListing.new(:mix_id => @mix.id, :track_number => params[:track][:track_number], :start_time => params[:track][:start_time])
          track.track_listings << track_listing
          respond_to do |format|
            if @mix.save && track_listing.save
              flash[:notice] = "<em>#{track.name}</em> was successfully added to <em>#{@mix.name}</em>."
              format.html { redirect_to :action => 'show', :id => @mix }
              format.xml  { head :ok }
            else
              format.html { redirect_to :action => "add_track", :id => @mix }
              format.xml  { render :xml => track.errors, :status => :unprocessable_entity }
            end
          end
        end
    else
      if params[:track][:name].empty?
        redirect_to :action => 'add_track', :id => @mix
      else
        flash[:notice] = "This track isn`t in the database yet. You can create it now."
        redirect_to :controller => 'tracks', :action => 'new', :track => params[:track], :mix_id => @mix.id
      end
    end
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This item isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end

  # GET /albums/1/edit
  def edit
    @mix = Mix.find(params[:id])
    @page_title = "Edit #{h @mix.name}"
     rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This mix isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end

  def create
    @page_title = "Create a new Mix"
    if params[:choices].empty?
      create_new
    else
      mix = Mix.find(params[:choices])
      notice = "This mix is already in the database.<br>"
      notice += "<br>You can add it to an <em>artist</em>." if album.artist_id.nil?
      flash[:notice] = notice
      redirect_to :action => 'show', :id => params[:choices]
    end
  end

  def add_artist
    @mix = Mix.find(params[:id])
    @page_title = "Add an Artist to #{h @mix.name}"
     rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This mix isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def check_added_artist
    @mix = Mix.find(params[:id])
    artist = Artist.find(:first, :conditions => ["name = ?", params[:artist][:name]]) if params[:artist][:name]
    unless artist.nil?
      @mix.artist_id = artist.id
      respond_to do |format|
        if @mix.save
          flash[:notice] = 'Mix was successfully updated.'
          format.html { redirect_to(@mix) }
          format.xml  { head :ok }
        else
          format.html { render :action => "edit" }
          format.xml  { render :xml => @mix.errors, :status => :unprocessable_entity }
        end
      end
    else
      if params[:artist][:name].empty?
        redirect_to :action => 'add_artist', :id => @mix
      else
        flash[:notice] = "This artist isn`t in the database yet. You can create him/her now."
        redirect_to :controller => 'artists', :action => 'new', :artist => params[:artist], :album_id => @mix.id
      end
    end
     rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This item isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end

  def destroy
    @mix = Mix.find(params[:id])
    @mix.destroy

    respond_to do |format|
      format.html { redirect_to(albums_url) }
      format.xml  { head :ok }
    end
     rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This mix isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def enter_release_date
    @mix = Mix.find(params[:id])
    @page_title = "Enter Release Date for #{h @mix.name}"
     rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This mix isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def update_release_date
    @mix = Mix.find(params[:id])

    respond_to do |format|
      if @mix.update_attribute( :release_date, Date.new(params[:date][:year].to_i) )
        flash[:notice] = 'Mix was successfully updated.'
        format.html { redirect_to(@mix) }
        format.xml  { head :ok }
      else
        format.html { render :action => "update_release_date" }
        format.xml  { render :xml => @mix.errors, :status => :unprocessable_entity }
      end
    end
     rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This mix isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  
  private
  
  def create_new
    @mix = Mix.new(params[:mix])
    @mix.artist_id = params[:artist_id]
    @mix.created_by = current_user.id
      respond_to do |format|
        if @mix.save
          flash[:notice] = "Mix was successfully created."
          if params[:track_id]
            format.html { redirect_to :controller => 'tracks',
                                      :action => 'check_added_mix',
                                      :id => params[:track_id],
                                      :mix => params[:mix]}
          elsif params[:artist_id]
            format.html { redirect_to :controller => 'artists',
                                      :action => 'check_added_mix',
                                      :id => params[:artist_id],
                                      :mix => params[:mix]}
          else
            format.html { redirect_to(@mix) }
            format.xml  { render :xml => @mix, :status => :created, :location => @mix }
          end
        else
          flash[:notice] = "There was a problem creating the item. Please try again."
          format.html { render :action => "new" }
          format.xml  { render :xml => @mix.errors, :status => :unprocessable_entity }
        end
     end
  end
  
  def get_tags
    @tags = Music.tag_counts( :order => ['RAND()'], :conditions => ["type = 'Mix'"], :limit => 40 )
  end
  
end
