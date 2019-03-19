class TracksController < ApplicationController
  require 'shared_controller.rb'
  include Shared
  
  layout 'music'
  
  auto_complete_for :track, :name
  
  before_filter :login_required,
                :except => [:index, :show, :tags]
  before_filter :get_tags, :except => [:tags, :show]
  
  # GET /tracks
  # GET /tracks.xml
  def index
   @page_title = "Tracks"
   @order = params[:order]
   @license = params[:license]
    cond = ['']
    if @license == 'free'
      cond[0] += "labels.license = 'free'"
    elsif @license == 'commercial'
      cond[0] += "labels.license = 'commercial'"
    end
    cond = nil if cond[0].blank?
    
    if @order == 'name'
      @tracks = Track.paginate( :page => params[:page],
                                :order => 'music.name',
                                :joins => ["LEFT OUTER JOIN music AS labels ON (music.label_id = labels.id)"],
                                :include => ['artist', 'label', 'ratings'],
                                :conditions => cond )
    elsif @order == 'comments'
      @tracks = Track.paginate( :page => params[:page],
                                :order => 'music.comments_count DESC, music.name',
                                :include => [:artist, :label, :ratings],
                                :joins => ["LEFT OUTER JOIN music AS labels ON (music.label_id = labels.id)"],
                                :conditions => cond)
    elsif @order == 'last_commented'
      @tracks = Track.paginate( :page => params[:page],
                                :include => [:artist, :label, :ratings, :comments],
                                :joins => ["LEFT OUTER JOIN music AS labels ON (music.label_id = labels.id)"],
                                :order => 'comments.created_at DESC, music.name',
                                :conditions => cond )
    elsif @order == 'loves'
      @tracks = Track.paginate( :page => params[:page],
                                :order => 'music.favourites_count DESC, music.name',
                                :include => [:artist, :label, :ratings],
                                :joins => ["LEFT OUTER JOIN music AS labels ON (music.label_id = labels.id)"],
                                :conditions => cond)
    elsif @order == 'rating'
      @tracks = Track.paginate( :page => params[:page],
                                :include => [:artist, :label, :ratings],
                                :joins => ["LEFT OUTER JOIN music AS labels ON (music.label_id = labels.id)"],
                                :group => 'music.id',
                                :order => 'AVG(ratings.rating) DESC',
                                :conditions => cond )
    else
      @tracks = Track.paginate( :page => params[:page],
                                :order => 'music.created_at DESC, music.name',
                                :joins => ["LEFT OUTER JOIN music AS labels ON (music.label_id = labels.id)"],
                                :conditions => cond,
                                :include => [:artist, :label, :ratings] )
    end  
    
    set_page_counts( Track.count(:all, :joins => ["LEFT OUTER JOIN music AS labels ON (music.label_id = labels.id)"], :conditions => cond), Music::per_page )
    
    respond_to do |format|
      format.html { render :action => 'index' }
      format.xml  { render :xml => @tarcks }
    end
  end
  
  def tags
    @page_title = "Tracks Tags"
    @tags = Music.tag_counts( :conditions => ["type = 'Track'"] )
  end

  # GET /tracks/1
  # GET /tracks/1.xml
  def show
      @track = Track.find(params[:id], :include => [:video, :albums, :mixes])
      @page_title = h(@track.name)
      @page_title += ' by ' +h(@track.artist.name) if @track.artist
      @page_title += ', ' + @track.release_date.year.to_s if @track.release_date
      @tags = @track.tag_counts(  :conditions => ["type = 'Track'"]  )
      @rating_count = @track.ratings.size
      @ur = Rating.find(:first, :conditions => [ "user_id = ? AND rateable_id = ? AND rateable_type ='Music'", current_user, params[:id] ]) if current_user
      @love = @track.users.index( current_user ) if current_user
      @comments = Comment.paginate :page => params[:page],
                                  :include => ['report'],
                                  :conditions => ["commentable_id = ? AND commentable_type ='Music'", @track.id],
                                  :order => 'created_at DESC'
      @comment = Comment.new
      
      respond_to do |format|
        format.html # show.html.erb
        format.xml  { render :xml => @track }
    end
    rescue ActiveRecord::RecordNotFound
      flash[:notice] = "This tack isn`t in the databse. It might have been removed."
      redirect_to :action => 'index'
  end
  
  def tag
    @tag = params[:id]
    @page_title = "Tag #{h @tag} on Tracks"
    
    if params[:order] == 'name'
      tagged = Music.tagged_with( @tag, :on => :tags, :conditions => ["type = 'Track'"] ).by_name
      @tracks = tagged.paginate( :page => params[:page] )
    elsif params[:order] == 'comments'
      tagged = Music.tagged_with( @tag, :on => :tags, :conditions => ["type = 'Track'"] ).by_comments
      @tracks = tagged.paginate( :page => params[:page] )
    elsif params[:order] == 'last_commented'
      tagged = Music.tagged_with( @tag, :on => :tags, :conditions => ["type = 'Track'"] ).by_comments_date
      @tracks = tagged.paginate( :page => params[:page] )
    elsif params[:order] == 'loves'
      tagged = Music.tagged_with( @tag, :on => :tags, :conditions => ["type = 'Track'"] ).by_loves
      @tracks = tagged.paginate( :page => params[:page] )
    elsif params[:order] == 'rating'
      tagged = Music.tagged_with( @tag, :on => :tags, :conditions => ["type = 'Track'"] ).by_rating
      @tracks = tagged.paginate( :page => params[:page] )
    else
      tagged = Music.tagged_with( @tag, :on => :tags, :conditions => ["type = 'Track'"] ).by_date
      @tracks = tagged.paginate( :page => params[:page] )
    end
    
    set_page_counts( tagged.length, Music::per_page )
    
  end
  
  def embed_video
    @track = Track.find(params[:id])
    query = @track.name
    query += '+' + @track.artist.name if @track.artist
    #query += '+' + @track.label.name if @track.label
    si = params[:start_index] ? params[:start_index] : 1
    @youtube = YouTube.find( query,
                            :orderby => :relevance,
                            :start_index => si,
                            :max_results => 15,
                            :racy => :include)

    respond_to do |format|
      if request.xhr?
        format.js
      else
        format_html redirect_to(:action => 'show', :id => @track)
      end
    end
  end
  
  def embed
    @track = Track.find(params[:id])
    YouTube.find_by_id(params[:video_id]) rescue nil
      video = Video.new( :youtube_id => params[:video_id], :track_id => @track.id )
      if video.save
        respond_to do |format|
          flash[:notice] = "Successfully embedded the video."
          format.html { redirect_to(track_path @track) }
          format.xml  { head :ok }
        end
      else
        respond_to do |format|
          flash[:error] = "There was a problem embedding the video."
          format.html { render :action => "embed" }
          format.xml  { render :xml => video.errors, :status => :unprocessable_entity }        
        end
      end
    
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This track isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  

  # GET /tracks/new
  # GET /tracks/new.xml
  def new
    @page_title = "New Track"
    @track = Track.new(params[:track])
    @artist = Artist.find(params[:artist_id]) if params[:artist_id]
    @label = Label.find(params[:label_id]) if params[:label_id]
    @album = Album.find(params[:album_id]) if params[:album_id]
    @mix = Mix.find(params[:mix_id]) if params[:mix_id]

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @track }
    end
  end
  
  def check_new
    @intended = params[:track]
    unless @intended[:name].blank?
      equal = Track.find(:first, :conditions => [ "name = ?", @intended[:name] ])
      if equal.blank?
        @similars = Track.find(:all, :conditions => ["name like ?", '%' + @intended[:name] + '%'],
                                :order => 'name')
        create_new if @similars.empty?
      else
        notice = "This track is already in the database.<br>"
        notice += "<br>You can add it to a <em>label</em>." if equal.label_id.nil?
        notice += "<br>And you can add it to an <em>artist</em>." if equal.artist_id.nil?
        flash[:notice] = notice
        redirect_to :action => 'show', :id => equal.id
      end
    else
    redirect_to :action => 'new'
    end
  end

  # GET /tracks/1/edit
  def edit
    @track = Track.find(params[:id])
    @page_title = "Edit Track #{h @track.name}"
     rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This track isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end

  # POST /tracks
  # POST /tracks.xml
  def create
    if params[:choices].empty?
      create_new
    else
      track = Track.find(params[:choices])
      notice = "This track is already in the database.<br>"
      notice += "<br>You can add it to a <em>label</em>." if track.label_id.nil?
      notice += "<br>And you can add it to an <em>artist</em>." if track.artist_id.nil?
      flash[:notice] = notice
      redirect_to :action => 'show', :id => params[:choices]
    end
  end

  def add_label
    @track = Track.find(params[:id])
    @page_title = "Add a label to #{h @track.name}"
     rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This track isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def check_added_label
    @track = Track.find(params[:id])
    label = Label.find(:first, :conditions => ["name = ?", params[:label][:name]])
    unless label.nil?
      @track.label_id = label.id
      flash[:notice] = 'Track was successfully updated.'
      
      ActiveRecord::Base.transaction do
        if @track.artist
          artist = @track.artist
          unless artist.labels.index(@track.label)
            artist.labels << @track.label
            flash[:notice] += "<br>And <em>#{@track.label.name}</em> was added to <em>#{@track.artist.name}`s</em> labels."
          end
        end
        respond_to do |format|
          if @track.save
            format.html { redirect_to(@track) }
            format.xml  { head :ok }
          else
            format.html { render :action => "edit" }
            format.xml  { render :xml => @track.errors, :status => :unprocessable_entity }
          end
        end
      end
      
    else
      if params[:label][:name].empty?
        redirect_to :action => 'add_label', :id => @track
      else
        flash[:notice] = "This label isn`t in the database yet. You can create it now."
        redirect_to :controller => 'labels', :action => 'new', :label => params[:label], :track_id => @track.id
      end
    end
     rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This track isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def add_artist
    @track = Track.find(params[:id])
    @page_title = "Set the artist for #{h @track.name}"
     rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This track isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def check_added_artist
    @track = Track.find(params[:id])
    artist = Artist.find(:first, :conditions => ["name = ?", params[:artist][:name]]) if params[:artist][:name]
    unless artist.nil?
      @track.artist_id = artist.id
      respond_to do |format|
        if @track.save
          flash[:notice] = 'Track was successfully updated.'
          format.html { redirect_to(@track) }
          format.xml  { head :ok }
        else
          format.html { render :action => "edit" }
          format.xml  { render :xml => @track.errors, :status => :unprocessable_entity }
        end
      end
    else
      if params[:artist][:name].empty?
        redirect_to :action => 'add_artist', :id => @track
      else
        flash[:notice] = "This artist isn`t in the database yet. You can create him/her now."
        redirect_to :controller => 'artists', :action => 'new', :artist => params[:artist], :track_id => @track.id
      end
    end
     rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This item isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def add_album
    @track = Track.find(params[:id])
    @page_title = "Set an album for #{h @track.name}"
     rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This track isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def check_added_album
    @track = Track.find(params[:id])
    album = Album.find(:first, :conditions => ["name = ?", params[:album][:name]]) if params[:album][:name]
    unless album.nil?
      @track.albums << album
      respond_to do |format|
            flash[:notice] = 'Track was successfully updated.'
            format.html { redirect_to(@track) }
            format.xml  { head :ok }
      end
    else
      if params[:album][:name].empty?
        redirect_to :action => 'add_album', :id => @track
      else
        flash[:notice] = "This album isn`t in the database yet. You can create it now."
        redirect_to :controller => 'albums', :action => 'new', :album => params[:album], :track_id => @track.id
      end
    end
     rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This item isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def add_mix
    @track = Track.find(params[:id])
    @page_title = "Associate #{h @track.name} with a mix"
     rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This track isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def check_added_mix
    @track = Track.find(params[:id])
    mix = Mix.find(:first, :conditions => ["name = ?", params[:mix][:name]]) if params[:mix][:name]
    unless mix.nil?
      @track.mixes << mix
      respond_to do |format|
            flash[:notice] = 'Track was successfully updated.'
            format.html { redirect_to(@track) }
            format.xml  { head :ok }
      end
    else
      if params[:mix][:name].empty?
        redirect_to :action => 'add_mix', :id => @track
      else
        flash[:notice] = "This mix isn`t in the database yet. You can create it now."
        redirect_to :controller => 'mixes', :action => 'new', :mix => params[:mix], :track_id => @track.id
      end
    end
     rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This item isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end

  # DELETE /tracks/1
  # DELETE /tracks/1.xml
  def destroy
    @track = Track.find(params[:id])
    @track.destroy

    respond_to do |format|
      format.html { redirect_to(tracks_url) }
      format.xml  { head :ok }
    end
     rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This track isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def enter_release_date
    @track = Track.find(params[:id])
    @page_title = "Set the publication date for #{h @track.name}"
     rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This track isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def update_release_date
    @track = Track.find(params[:id])

    respond_to do |format|
      if @track.update_attribute( :release_date, Date.new(params[:date][:year].to_i) )
        flash[:notice] = 'Track was successfully updated.'
        format.html { redirect_to(@track) }
        format.xml  { head :ok }
      else
        format.html { render :action => "update_release_date" }
        format.xml  { render :xml => @track.errors, :status => :unprocessable_entity }
      end
    end
     rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This track isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  
  private
  
  def create_new
    @track = Track.new(params[:track])
    @track.artist_id = params[:artist_id]
    @track.label_id = params[:label_id]
    @track.created_by = current_user.id
      respond_to do |format|
        if @track.save
          flash[:notice] = "Track was successfully created."
          if params[:label_id]
            format.html { redirect_to :controller => 'labels',
                                      :action => 'check_added_track',
                                      :id => params[:label_id],
                                      :track => params[:track]}
          elsif params[:artist_id]
            format.html { redirect_to :controller => 'artist',
                                      :action => 'check_added_track',
                                      :id => params[:artist_id],
                                      :track => params[:track]}
          elsif params[:album_id]
            format.html { redirect_to :controller => 'albums',
                                      :action => 'check_added_track',
                                      :id => params[:album_id],
                                      :track => params[:track]}
          elsif params[:mix_id]
            format.html { redirect_to :controller => 'mixes',
                                      :action => 'check_added_track',
                                      :id => params[:mix_id],
                                      :track => params[:track]}
          else
            format.html { redirect_to(@track) }
            format.xml  { render :xml => @track, :status => :created, :location => @track }
          end
        else
          format.html { render :action => "new" }
          format.xml  { render :xml => @track.errors, :status => :unprocessable_entity }
        end
      end
  end
  
  def get_tags
    @tags = Music.tag_counts( :conditions => ["type = 'Track'"], :order => ['RAND()'], :limit => 40 )
  end

end
