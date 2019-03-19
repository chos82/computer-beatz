class ArtistsController < ApplicationController
  before_filter :login_required, :except => [:index, :show, :albums, :labels, :tracks, :tags]
  before_filter :get_tags, :except => [:tags, :show]
  
  require 'shared_controller.rb'
  include Shared
  
  layout 'music'
  
  auto_complete_for :artist, :name
  
  # GET /artists
  # GET /artists.xml
  def index
    @page_title = "Artists"
    
    if params[:order] == 'name'
      @artists = Artist.paginate( :page => params[:page], :include => [:ratings], :order => 'name' )
    elsif params[:order] == 'comments'
      @artists = Artist.paginate( :page => params[:page], :include => [:ratings], :order => 'comments_count DESC, name' )
    elsif params[:order] == 'last_commented'
      @artists = Artist.paginate( :page => params[:page], :include => [:ratings, :comments], :order => 'comments.created_at DESC, name' )
    elsif params[:order] == 'loves'
      @artists = Artist.paginate( :page => params[:page], :include => [:ratings], :order => 'favourites_count DESC, name' )
    elsif params[:order] == 'rating'
      @artists = Artist.paginate( :page => params[:page], :include => [:ratings], :group => 'music.id', :order => 'AVG(ratings.rating) DESC' )
    else
      @artists = Artist.paginate( :page => params[:page], :include => [:ratings], :order => 'created_at DESC, name' )
    end
    
    set_page_counts( Artist.count(:all), Music::per_page )
    
    respond_to do |format|
      format.html
      format.xml  { render :xml => @artists }
    end
  end
  
  def tags
    @page_title = "Artists Tags"
    @tags = Music.tag_counts( :conditions => ["type = 'Artist'"] )
  end

  # GET /artists/1
  # GET /artists/1.xml
  def show
      @artist = Artist.find(params[:id], :include => ['report'])
      @page_title = h(@artist.name)
      @tags = @artist.tag_counts(  :conditions => ["type = 'Artist'"]  )
      @page_title = @artist.name.downcase
      @rating_count = @artist.ratings.size
      @ur = Rating.find(:first, :conditions => [ "user_id = ? AND rateable_id = ? AND rateable_type ='Music'", current_user.id, params[:id] ]) if current_user
      @love = @artist.users.index( current_user ) if current_user
      @comments = Comment.paginate :page => params[:page],
                                   :include => ['user', 'report'],
                                   :conditions => ["commentable_id = ? AND commentable_type ='Music'", @artist.id],
                                   :order => 'created_at DESC'
      @comment = Comment.new

      respond_to do |format|
        format.html # show.html.erb
        format.xml  { render :xml => @artist }
      end
      rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This artist isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def tag
    @tag = params[:id]
    @page_title = "Tag #{h @tag} on Artists"
    
    if params[:order] == 'name'
      tagged = Music.tagged_with( @tag, :on => :tags, :conditions => ["type = 'Artist'"] ).by_name
      @artists = tagged.paginate( :page => params[:page] )
    elsif params[:order] == 'comments'
      tagged = Music.tagged_with( @tag, :on => :tags, :conditions => ["type = 'Artist'"] ).by_comments
      @artists = tagged.paginate( :page => params[:page] )
    elsif params[:order] == 'last_commented'
      tagged = Music.tagged_with( @tag, :on => :tags, :conditions => ["type = 'Artist'"] ).by_comments_date
      @artists = tagged.paginate( :page => params[:page] )
    elsif params[:order] == 'loves'
      tagged = Music.tagged_with( @tag, :on => :tags, :conditions => ["type = 'Artist'"] ).by_loves
      @artists = tagged.paginate( :page => params[:page] )
    elsif params[:order] == 'rating'
      tagged = Music.tagged_with( @tag, :on => :tags, :conditions => ["type = 'Artist'"] ).by_rating
      @artists = tagged.paginate( :page => params[:page] )
    else
      tagged = Music.tagged_with( @tag, :on => :tags, :conditions => ["type = 'Artist'"] ).by_date
      @artists = tagged.paginate( :page => params[:page] )
    end
    
    set_page_counts( tagged.length, Music::per_page )
  end

  # GET /artists/new
  # GET /artists/new.xml
  def new
    @artist = Artist.new(params[:artist])
    @page_title = 'New Artist'
    @track = Track.find(params[:track_id]) if params[:track_id]
    @label = Label.find(params[:label_id]) if params[:label_id]
    @album = Album.find(params[:album_id]) if params[:album_id]
    @mix = Mix.find(params[:mix_id]) if params[:mix_id]

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @artist }
    end
  end

  # GET /artists/1/edit
  def edit
    @artist = Artist.find(params[:id])
  end
  
  def check_new
    @page_title = 'new artist'
    @intended = params[:artist]
    @intended[:www].gsub! /http:\/\//, ''
    unless @intended[:name].blank?
      equal = Artist.find(:first, :conditions => [ "name = ?", @intended[:name] ])
      if equal.blank?
        @similars = Artist.find(:all, :conditions => ["name like ?", '%' + @intended[:name] + '%'],
                                :order => 'name')
        create_new if @similars.empty?
      else
        notice = "This artist is already in the database.<br>" +
                 "Maybe you want to add a <em>track</em>?"
        notice += "<br>And you can add a <em>homepage</em> for this artist." if equal.www.blank?
        flash[:notice] = notice
        redirect_to :action => 'tracks', :id => equal.id
      end
    else
      redirect_to :action => 'new'
    end
  end

  # POST /artists
  # POST /artists.xml
  def create
    @page_title = 'create artist'
    
    if params[:choices].empty?
      create_new
    else
      artist = Artist.find(params[:choices])
      if params[:track_id]
        redirect_to :controller => 'tracks',
                    :action => 'check_added_artist',
                    :id => params[:track_id],
                    :artist => {:name => artist.name}#,
                    #:method => :put
      else
        notice = "This artist is already in the database.<br>" +
                 "Maybe you want to add a <em>track</em>?"
        notice += "<br>And you can add a <em>homepage</em> for this artist." if artist.www.blank?
        flash[:notice] = notice
        redirect_to :action => 'show', :id => params[:choices]
      end
    end
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This artist isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
   
  end

  # PUT /artists/1
  # PUT /artists/1.xml
  def update
    @artist = Artist.find(params[:id])

    respond_to do |format|
      if @artist.update_attribute(:www, params[:artist][:www])
        flash[:notice] = 'Artist was successfully updated.'
        format.html { redirect_to(@artist) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @artist.errors, :status => :unprocessable_entity }
      end
    end
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This artist isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end

  # DELETE /artists/1
  # DELETE /artists/1.xml
  def destroy
    @artist = Artist.find(params[:id])
    @artist.destroy

    respond_to do |format|
      format.html { redirect_to(artists_url) }
      format.xml  { head :ok }
    end
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This artist isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def albums
    @artist = Artist.find(params[:id])
    @page_title = "Albums of #{h @artist.name}"
    
    if params[:order] == 'name'
      @albums = Album.paginate( :page => params[:page],
                                :order => 'name',
                                :conditions => ['artist_id = ?', @artist.id] )
    elsif params[:order] == 'comments'
      @albums = Album.paginate( :page => params[:page],
                                :order => 'comments_count DESC, name',
                                :conditions => ['artist_id = ?', @artist.id] )
    elsif params[:order] == 'last_commented'
      @albums = Album.paginate( :page => params[:page],
                                :include => 'comments',
                                :order => 'comments.created_at DESC, name',
                                :conditions => ['artist_id = ?', @artist.id] )
    elsif params[:order] == 'loves'
      @albums = Album.paginate( :page => params[:page],
                                :order => 'favourites_count DESC, name',
                                :conditions => ['artist_id = ?', @artist.id] )
    elsif params[:order] == 'rating'
      @albums = Album.paginate( :page => params[:page],
                                :include => 'ratings',
                                :group => 'music.id', :order => 'AVG(ratings.rating) DESC',
                                :conditions => ['artist_id = ?', @artist.id] )
    else
      @albums = Album.paginate( :page => params[:page],
                                :order => 'created_at DESC, name',
                                :conditions => ['artist_id = ?', @artist.id] )
    end
    
    set_page_counts( Album.count( :all, :conditions => ['artist_id = ?', @artist.id]), Music::per_page )
        
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This artist isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def mixes
    @artist = Artist.find(params[:id])
    @page_title = "Mixes of #{h @artist.name}"
    
    if params[:order] == 'comments'
      @mixes = Mix.paginate( :page => params[:page],
                                :order => 'comments_count DESC, name',
                                :conditions => ['artist_id = ?', @artist.id] )
    elsif params[:order] == 'last_commented'
      @mixes = Mix.paginate( :page => params[:page],
                                :include => 'comments',
                                :order => 'comments.created_at DESC, name',
                                :conditions => ['artist_id = ?', @artist.id] )
    elsif params[:order] == 'loves'
      @mixes = Mix.paginate( :page => params[:page],
                                :order => 'favourites_count DESC, name',
                                :conditions => ['artist_id = ?', @artist.id] )
    elsif params[:order] == 'rating'
      @mixes = Mix.paginate( :page => params[:page],
                                :include => 'ratings',
                                :group => 'music.id', :order => 'AVG(ratings.rating) DESC',
                                :conditions => ['artist_id = ?', @artist.id] )
    else
      @mixes = Mix.paginate( :page => params[:page],
                                :order => 'name',
                                :conditions => ['artist_id = ?', @artist.id] )
    end
    
    set_page_counts( Mix.count( :all, :conditions => ['artist_id = ?', @artist.id]), Music::per_page )
        
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This artist isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def labels
    @artist = Artist.find(params[:id])
    @page_title = "Labels #{h @artist.name} published on"
    
    if params[:order] == 'name'
      @labels = Label.paginate( :page => params[:page],
                                :order => 'music.name',
                                :include => 'artists',
                                :conditions => ["artists_labels.artist_id = ?", @artist.id] )
    elsif params[:order] == 'comments'
      @labels = Label.paginate( :page => params[:page],
                                :order => 'music.comments_count DESC, music.name',
                                :include => 'artists',
                                :conditions => ["artists_labels.artist_id = ?", @artist.id] )
    elsif params[:order] == 'last_commented'
      @labels = Label.paginate( :page => params[:page],
                                :include => ['comments', 'artists'],
                                :order => 'comments.created_at DESC, music.name',
                                :conditions => ["artists_labels.artist_id = ?", @artist.id] )
    elsif params[:order] == 'loves'
      @labels = Label.paginate( :page => params[:page],
                                :order => 'music.favourites_count DESC, music.name',
                                :include => 'artists',
                                :conditions => ["artists_labels.artist_id = ?", @artist.id] )
    elsif params[:order] == 'rating'
      @labels = Label.paginate( :page => params[:page],
                                :include => ['ratings', 'artists'],
                                :group => 'music.id', :order => 'AVG(ratings.rating) DESC',
                                :conditions => ["artists_labels.artist_id = ?", @artist.id] )
    else
      @labels = Label.paginate( :page => params[:page],
                                :order => 'music.created_at DESC, music.name',
                                :include => 'artists',
                                :conditions => ["artists_labels.artist_id = ?", @artist.id] )
    end
    
    set_page_counts( Label.count( :all, :include => 'artists', :conditions => ["artists_labels.artist_id = ?", @artist.id] ), Music::per_page )
    
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This artist isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def tracks
    @artist = Artist.find(params[:id])
    @page_title = "Tracks #{h @artist.name} published"
    
    if params[:order] == 'name'
      @tracks = Track.paginate( :page => params[:page],
                                :order => 'name',
                                :conditions => ['artist_id = ?', @artist.id] )
    elsif params[:order] == 'comments'
      @tracks = Track.paginate( :page => params[:page],
                                :order => 'comments_count DESC, name',
                                :conditions => ['artist_id = ?', @artist.id] )
    elsif params[:order] == 'last_commented'
      @tracks = Track.paginate( :page => params[:page],
                                :include => 'comments',
                                :order => 'comments.created_at DESC, name',
                                :conditions => ['artist_id = ?', @artist.id] )
    elsif params[:order] == 'loves'
      @tracks = Track.paginate( :page => params[:page],
                                :order => 'favourites_count DESC, name',
                                :conditions => ['artist_id = ?', @artist.id] )
    elsif params[:order] == 'rating'
      @tracks = Track.paginate( :page => params[:page],
                                :include => 'ratings',
                                :group => 'music.id', :order => 'AVG(ratings.rating) DESC',
                                :conditions => ['artist_id = ?', @artist.id] )
    else
      @tracks = Track.paginate( :page => params[:page],
                                :order => 'created_at DESC, name',
                                :conditions => ['artist_id = ?', @artist.id] )
    end
    
    set_page_counts( Track.count( :all, :conditions => ['artist_id = ?', @artist.id]), Music::per_page )
        
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This artist isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def add_track
    @artist = Artist.find(params[:id])
    @page_title = "Add a Track to #{h @artist.name}"
    
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This artist isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def check_added_track
    @artist = Artist.find(params[:id])
    track = Track.find(:first, :conditions => ["name = ?", params[:track][:name]]) if params[:track][:name]
    unless track.nil?
      if track.artist_id.nil?
        track.artist_id = @artist.id
        respond_to do |format|
          if track.save
            flash[:notice] = "<em>#{track.name}</em> was successfully added to <em>#{@artist.name}</em>."
            format.html { redirect_to :action => 'tracks', :id => @artist }
            format.xml  { head :ok }
          else
            format.html { render :action => "add_tarck", :id => @artist }
            format.xml  { render :xml => @tartist.errors, :status => :unprocessable_entity }
          end
        end
      else
        owing_artist = Artist.find(track.artist_id)
        flash[:notice] = "This track already belongs to <em>#{owing_artist.name}</em>.<br>" + 
                         "You think that is wrong? Then contact please."
        redirect_to new_music_report_path(track)
      end
    else
      if params[:track][:name].empty?
        redirect_to :action => 'add_track', :id => @artist
      else
        flash[:notice] = "This track isn`t in the database yet. You can create it now."
        redirect_to :controller => 'tracks', :action => 'new', :track => params[:track], :artist_id => @artist.id
      end
    end
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This artist isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def add_album
    @artist = Artist.find(params[:id])
    @page_title = "Add an Album to #{h @artist.name}"
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This artist isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def check_added_album
    @artist = Artist.find(params[:id])
    album = Album.find(:first, :conditions => ["name = ?", params[:album][:name]]) if params[:album][:name]
    unless album.nil?
      if album.artist_id.nil?
        album.artist_id = @artist.id
        respond_to do |format|
          if album.save
            flash[:notice] = "<em>#{album.name}</em> was successfully added to <em>#{@artist.name}</em>."
            format.html { redirect_to :action => 'albums', :id => @artist }
            format.xml  { head :ok }
          else
            format.html { render :action => "add_album", :id => @artist }
            format.xml  { render :xml => @artist.errors, :status => :unprocessable_entity }
          end
        end
      else
        owing_artist = Artist.find(album.artist_id)
        flash[:notice] = "This album already belongs to <em>#{owing_artist.name}</em>.<br>" + 
                         "You think that is wrong? Then contact please."
        redirect_to new_music_report_path(album)
      end
    else
      if params[:album][:name].empty?
        redirect_to :action => 'add_album', :id => @artist
      else
        flash[:notice] = "This album isn`t in the database yet. You can create it now."
        redirect_to :controller => 'album', :action => 'new', :album => params[:album], :artist_id => @artist.id
      end
    end
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This artist isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def add_mix
    @artist = Artist.find(params[:id])
    @page_title = "Add an Mix to #{h @artist.name}"
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This artist isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def check_added_mix
    @artist = Artist.find(params[:id])
    mix = Mix.find(:first, :conditions => ["name = ?", params[:mix][:name]]) if params[:mix][:name]
    unless mix.nil?
      if mix.artist_id.nil?
        mix.artist_id = @artist.id
        respond_to do |format|
          if mix.save
            flash[:notice] = "<em>#{mix.name}</em> was successfully added to <em>#{@artist.name}</em>."
            format.html { redirect_to :action => 'mixes', :id => @artist }
            format.xml  { head :ok }
          else
            format.html { render :action => "add_mix", :id => @artist }
            format.xml  { render :xml => @artist.errors, :status => :unprocessable_entity }
          end
        end
      else
        owing_artist = Artist.find(mix.artist_id)
        flash[:notice] = "This mix already belongs to <em>#{owing_artist.name}</em>.<br>" + 
                         "You think that is wrong? Then contact please."
        redirect_to new_music_report_path(mix)
      end
    else
      if params[:mix][:name].empty?
        redirect_to :action => 'add_mix', :id => @artist
      else
        flash[:notice] = "This mix isn`t in the database yet. You can create it now."
        redirect_to :controller => 'mix', :action => 'new', :mix => params[:mix], :artist_id => @artist.id
      end
    end
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This artist isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  

  private
  
  def create_new
    @artist = Artist.new(params[:artist])
    @artist.created_by = current_user.id
      respond_to do |format|
        if @artist.save
          flash[:notice] = 'Artist was successfully created.'
          if params[:track_id]
            format.html { redirect_to :controller => 'tracks',
                                      :action => 'check_added_artist',
                                      :id => params[:track_id],
                                      :artist => params[:artist]}
          elsif params[:label_id]
            format.html { redirect_to :controller => 'labels',
                                      :action => 'check_added_artist',
                                      :id => params[:label_id],
                                      :artist => params[:artist]}
          elsif params[:album_id]
            format.html { redirect_to :controller => 'albums',
                                      :action => 'check_added_artist',
                                      :id => params[:album_id],
                                      :artist => params[:artist]}
          elsif params[:mix_id]
            format.html { redirect_to :controller => 'mixes',
                                      :action => 'check_added_artist',
                                      :id => params[:mix_id],
                                      :artist => params[:artist]}
          else
            format.html { redirect_to(@artist) }
            format.xml  { render :xml => @artist, :status => :created, :location => @artist }
          end
        else
          format.html { render :action => "new" }
          format.xml  { render :xml => @artist.errors, :status => :unprocessable_entity }
        end
      end
  end
  
  def get_tags
    @tags = Music.tag_counts( :order => ['RAND()'],:conditions => ["type = 'Artist'"], :limit => 40 )
  end
  
end
