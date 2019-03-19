class LabelsController < ApplicationController
  before_filter :login_required, :except => [:index, :show, :albums, :artists, :tracks, :tags]
  before_filter :get_tags, :except => [:tags, :show]
  
  require 'shared_controller.rb'
  include Shared
  
  layout 'music'
  
  auto_complete_for :label, :name
              
  # GET /labels
  # GET /labels.xml
  def index
   @page_title = "Labels"
   @order = params[:order]
   @license = params[:license]
    cond = ['']
    if @license == 'free'
      cond[0] += "license = 'free'"
    elsif @license == 'commercial'
      cond[0] += "license = 'commercial'"
    end
    cond = nil if cond[0].blank?
    
   if @order == 'name'
      @labels = Label.paginate( :page => params[:page], :order => 'name', :conditions => cond ,:include => [:ratings] )
    elsif @order == 'comments'
      @labels = Label.paginate( :page => params[:page], :order => 'comments_count DESC, name', :conditions => cond, :include => [:ratings] )
    elsif @order == 'last_commented'
      @labels = Label.paginate( :page => params[:page], :include => [:ratings, :comments], :order => 'comments.created_at DESC, name', :conditions => cond )
    elsif @order == 'loves'
      @labels = Label.paginate( :page => params[:page], :order => 'favourites_count DESC, name', :conditions => cond, :include => [:ratings] )
    elsif @order == 'rating'
      @labels = Label.paginate( :page => params[:page], :include => 'ratings', :group => 'music.id', :order => 'AVG(ratings.rating) DESC', :conditions => cond )
    else
      @labels = Label.paginate( :page => params[:page], :order => 'created_at, name', :conditions => cond, :include => [:ratings] )
    end  
   
   set_page_counts( Label.count(:all, :conditions => cond), Music::per_page )
    
    respond_to do |format|
      format.html
      format.xml  { render :xml => @labels }
    end
  end
  
  def tags
    @page_title = "Labels Tags"
    @tags = Label.tag_counts( :conditions => ["type = 'Label'"] )
  end

  # GET /labels/1
  # GET /labels/1.xml
  def show
    begin
      @label = Label.find(params[:id], :include => ['report'])
      @page_title = h @label.name
      @rating_count = @label.ratings.size
      @tags = @label.tag_counts
      @ur = Rating.find(:first, :conditions => [ "user_id = ? AND rateable_id = ? AND rateable_type ='Music'", current_user, params[:id] ]) if current_user
      @love = @label.users.index( current_user ) if current_user
      @comments = Comment.paginate :page => params[:page],
                                  :include => ['report'],
                                  :conditions => ["commentable_id = ? AND commentable_type ='Music'", @label.id],
                                  :order => 'created_at DESC'
      @comment = Comment.new

      respond_to do |format|
        format.html # show.html.erb
        format.xml  { render :xml => @label }
      end
    end
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This label isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def tag
    @tag = params[:id]
    @page_title = "Tag #{h @tag} on Labels"
    
    if params[:order] == 'name'
      tagged = Music.tagged_with( @tag, :on => :tags, :conditions => ["type = 'Label'"] ).by_name
      @labels = tagged.paginate( :page => params[:page] )
    elsif params[:order] == 'comments'
      tagged = Music.tagged_with( @tag, :on => :tags, :conditions => ["type = 'Label'"] ).by_comments
      @labels = tagged.paginate( :page => params[:page] )
    elsif params[:order] == 'last_commented'
      tagged = Music.tagged_with( @tag, :on => :tags, :conditions => ["type = 'Label'"] ).by_comments_date
      @labels = tagged.paginate( :page => params[:page] )
    elsif params[:order] == 'loves'
      tagged = Music.tagged_with( @tag, :on => :tags, :conditions => ["type = 'Label'"] ).by_loves
      @labels = tagged.paginate( :page => params[:page] )
    elsif params[:order] == 'rating'
      tagged = Music.tagged_with( @tag, :on => :tags, :conditions => ["type = 'Label'"] ).by_rating
      @labels = tagged.paginate( :page => params[:page] )
    else
      tagged = Music.tagged_with( @tag, :on => :tags, :conditions => ["type = 'Label'"] ).by_date
      @labels = tagged.paginate( :page => params[:page] )
    end
    
    set_page_counts( tagged.length, Music::per_page )
    
  end

  # GET /labels/new
  # GET /labels/new.xml
  def new
    @page_title = "New Album"
    @label = Label.new(params[:label])
    @page_title = 'new label'
    @track = Track.find(params[:track_id]) if params[:track_id]
    @album = Album.find(params[:album_id]) if params[:album_id]

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @label }
    end
  end

  # GET /labels/1/edit
  def edit
    @label = Label.find(params[:id])
    @page_title = "Edit #{h @label.name}"
  end
  
  def check_new
    @page_title = 'new label'
    @intended = params[:label]
    @intended[:www].gsub! /http:\/\//, ''
    unless @intended[:name].blank?
      equal = Label.find(:first, :conditions => [ "name = ?", @intended[:name] ])
      if equal.blank?
        @similars = Label.find(:all, :conditions => ["name like ?", '%' + @intended[:name] + '%'],
                                :order => 'name')
        create_new if @similars.empty?
      else
        notice = "This label is already in the database.<br>" +
                 "Maybe you want to add a <em>track</em>, or an <em>artist</em>?"
        notice += "<br>And you can add a <em>homepage</em> for this label." if equal.www.blank?
        flash[:notice] = notice
        redirect_to :action => 'show', :id => equal.id
      end
    else
      redirect_to :action => 'new'
    end
  end

  # POST /labels
  # POST /labels.xml
  def create
    @label = Label.new(params[:label])
    @page_title = 'create label'

    if params[:choices].empty?
      create_new
    else
      label = Label.find(params[:choices])
      if params[:track_id]
        redirect_to :controller => 'tracks',
                    :action => 'check_added_label',
                    :id => params[:track_id],
                    :label => {:name => label.name}#,
                    #:method => :put
      else
         notice = "This label is already in the database.<br>" +
               "Maybe you want to add a <em>track</em> or an <em>artist</em>?"
        notice += "<br>And you can add a <em>homepage</em> for this artist." if label.www.blank?
        flash[:notice] = notice
        redirect_to :action => 'show', :id => params[:choices]
      end
    end
    
  end

  # PUT /labels/1
  # PUT /labels/1.xml
  def update
    @label = Label.find(params[:id])

    respond_to do |format|
      if @label.update_attribute(:www, params[:label][:www])
        flash[:notice] = 'Label was successfully updated.'
        format.html { redirect_to(@label) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @label.errors, :status => :unprocessable_entity }
      end
    end
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This label isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def set_license
    @label = Label.find(params[:id])
    @page_title = "Set license for #{h @label.name}"
  end
  
  def update_license
    @label = Label.find(params[:id])

    respond_to do |format|
      if @label.update_attribute(:license, params[:label][:license])
        flash[:notice] = 'Label was successfully updated.'
        format.html { redirect_to(@label) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @label.errors, :status => :unprocessable_entity }
      end
    end
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This label isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end


  # DELETE /labels/1
  # DELETE /labels/1.xml
  def destroy
    @label = Label.find(params[:id])
    @label.destroy

    respond_to do |format|
      format.html { redirect_to(labels_url) }
      format.xml  { head :ok }
    end
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This label isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def artists
    @label = Label.find(params[:id])
    @page_title = "Show artists for #{h @label.name}"

    if params[:order] == 'name'
      @artists = Artist.paginate( :page => params[:page],
                                :order => 'music.name',
                                :include => 'labels',
                                :conditions => ["artists_labels.label_id = ?", @label.id] )
    elsif params[:order] == 'comments'
      @artists = Artist.paginate( :page => params[:page],
                                :order => 'music.comments_count DESC, music.name',
                                :include => 'labels',
                                :conditions => ["artists_labels.label_id = ?", @label.id] )
    elsif params[:order] == 'last_commented'
      @artists = Artist.paginate( :page => params[:page],
                                :include => ['comments', 'labels'],
                                :order => 'comments.created_at DESC, music.name',
                                :conditions => ["artists_labels.label_id = ?", @label.id] )
    elsif params[:order] == 'loves'
      @artists = Artist.paginate( :page => params[:page],
                                :order => 'music.favourites_count DESC, music.name',
                                :include => 'labels',
                                :conditions => ["artists_labels.label_id = ?", @label.id] )
    elsif params[:order] == 'rating'
      @artists = Artist.paginate( :page => params[:page],
                                :include => ['ratings', 'labels'],
                                :group => 'music.id', :order => 'AVG(ratings.rating) DESC',
                                :conditions => ["artists_labels.label_id = ?", @label.id] )
    else
      @artists = Artist.paginate( :page => params[:page],
                                  :order => 'music.created_at DESC, music.name',
                                  :include => 'labels',
                                  :conditions => ["artists_labels.label_id = ?", @label.id] )
    end
    
    set_page_counts( Artist.count( :all, :include => 'labels', :conditions => ["artists_labels.label_id = ?", @label.id] ), Music::per_page )
    
    
    @page_title = @label.name.downcase
      rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This label isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def tracks
    @label = Label.find(params[:id])
    @page_title = "Show tracks for #{h @label.name}"
    
    if params[:order] == 'name'
      @tracks = Track.paginate( :page => params[:page],
                                :order => 'name',
                                :conditions => ['label_id = ?', @label.id] )
    elsif params[:order] == 'comments'
      @tracks = Track.paginate( :page => params[:page],
                                :order => 'comments_count DESC, name',
                                :conditions => ['label_id = ?', @label.id] )
    elsif params[:order] == 'last_commented'
      @tracks = Track.paginate( :page => params[:page],
                                :include => 'comments',
                                :order => 'comments.created_at DESC, name',
                                :conditions => ['label_id = ?', @label.id] )
    elsif params[:order] == 'loves'
      @tracks = Track.paginate( :page => params[:page],
                                :order => 'favourites_count DESC, name',
                                :conditions => ['label_id = ?', @label.id] )
    elsif params[:order] == 'rating'
      @tracks = Track.paginate( :page => params[:page],
                                :include => 'ratings',
                                :group => 'music.id', :order => 'AVG(ratings.rating) DESC',
                                :conditions => ['label_id = ?', @label.id] )
    else
      @tracks = Track.paginate( :page => params[:page],
                                :order => 'created_at DESC, name',
                                :conditions => ['label_id = ?', @label.id] )
    end
    
    set_page_counts( Track.count( :all, :conditions => ['label_id = ?', @label.id]), Music::per_page )
    
    @page_title = @label.name.upcase
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This label isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def albums
    @label = Label.find(params[:id])
    @page_title = "Show albums for #{h @label.name}"
    
    if params[:order] == 'name'
      @albums = Album.paginate( :page => params[:page],
                                :order => 'name',
                                :conditions => ['label_id = ?', @label.id] )
    elsif params[:order] == 'comments'
      @albums = Album.paginate( :page => params[:page],
                                :order => 'comments_count DESC, name',
                                :conditions => ['label_id = ?', @label.id] )
    elsif params[:order] == 'last_commented'
      @albums = Album.paginate( :page => params[:page],
                                :include => 'comments',
                                :order => 'comments.created_at DESC, name',
                                :conditions => ['label_id = ?', @label.id] )
    elsif params[:order] == 'loves'
      @albums = Album.paginate( :page => params[:page],
                                :order => 'favourites_count DESC, name',
                                :conditions => ['label_id = ?', @label.id] )
    elsif params[:order] == 'rating'
      @albums = Album.paginate( :page => params[:page],
                                :include => 'ratings',
                                :group => 'music.id', :order => 'AVG(ratings.rating) DESC',
                                :conditions => ['label_id = ?', @label.id] )
    else
      @albums = Album.paginate( :page => params[:page],
                                :order => 'created_at DESC, name',
                                :conditions => ['label_id = ?', @label.id] )
    end
    
    set_page_counts( Album.count( :all, :conditions => ['label_id = ?', @label.id]), Music::per_page )
    
    @page_title = @label.name.upcase
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This label isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def add_artist
    @label = Label.find(params[:id])
    @page_title = "Add an artist to #{h @label.name}"
    @page_title = 'add artist'
  end
  
  def check_added_artist
    @label = Label.find(params[:id])
    artist = Artist.find(:first, :conditions => ["name = ?", params[:artist][:name]]) if params[:artist][:name]
    unless artist.nil?
      ActiveRecord::Base.transaction do
        unless @label.artists.index(artist)
          @label.artists << artist
          flash[:notice] = "<em>#{artist.name}</em> was successfully added to <em>#{@label.name}</em>."
        end
        respond_to do |format|
          if @label.save
            format.html { redirect_to :action => 'artists', :id => @label }
            format.xml  { head :ok }
          else
            format.html { render :action => "add_artist", :id => @label }
            format.xml  { render :xml => @track.errors, :status => :unprocessable_entity }
          end
        end
      end
    else
      if params[:artist][:name].empty?
        redirect_to :action => 'add_artist', :id => @label
      else
        flash[:notice] = "This artist isn`t in the database yet. You can create him/her now."
        redirect_to :controller => 'artists', :action => 'new', :artist => params[:artist], :label_id => @label.id
      end
    end
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This label isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def add_track
    @label = Label.find(params[:id])
    @page_title = "Add a tarck to #{h @label.name}"
    @page_title = 'add track'
  end
  
  def check_added_track
    @label = Label.find(params[:id])
    track = Track.find(:first, :conditions => ["name = ?", params[:track][:name]]) if params[:track][:name]
    unless track.nil?
      if track.label_id.nil?
        track.label_id = @label.id
        respond_to do |format|
          if track.save
            flash[:notice] = "<em>#{track.name}</em> was successfully added to <em>#{@label.name}</em>."
            format.html { redirect_to :action => 'tracks', :id => @label }
            format.xml  { head :ok }
          else
            format.html { render :action => "add_track", :id => @label }
            format.xml  { render :xml => track.errors, :status => :unprocessable_entity }
          end
        end
      else
        owing_label = Label.find(track.label_id)
        flash[:error] = "This track already belongs to <em>#{owing_label.name}</em>.<br>" + 
                         "You think that is wrong? Then contact please."
        redirect_to new_music_report_path( track )
      end
    else
      if params[:track][:name].empty?
        redirect_to :action => 'add_track', :id => @label
      else
        flash[:notice] = "This track isn`t in the database yet. You can create it now."
        redirect_to :controller => 'tracks', :action => 'new', :track => params[:track], :label_id => @label.id
      end
    end
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This label isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def add_album
    @label = Label.find(params[:id])
    @page_title = "Add an album to #{h @label.name}"
  end
  
  def check_added_album
    @label = Label.find(params[:id])
    album = Album.find(:first, :conditions => ["name = ?", params[:album][:name]]) if params[:album][:name]
    unless album.nil?
      if album.label_id.nil?
        album.label_id = @label.id
        respond_to do |format|
          if album.save
            flash[:notice] = "<em>#{album.name}</em> was successfully added to <em>#{@label.name}</em>."
            format.html { redirect_to :action => 'albums', :id => @label }
            format.xml  { head :ok }
          else
            format.html { render :action => "add_album", :id => @label }
            format.xml  { render :xml => album.errors, :status => :unprocessable_entity }
          end
        end
      else
        owing_label = Label.find(album.label_id)
        flash[:error] = "This album already belongs to <em>#{owing_label.name}</em>.<br>" + 
                         "You think that is wrong? Then contact please."
        redirect_to new_music_report_path( album )
      end
    else
      if params[:album][:name].empty?
        redirect_to :action => 'add_album', :id => @label
      else
        flash[:notice] = "This album isn`t in the database yet. You can create it now."
        redirect_to :controller => 'albums', :action => 'new', :album => params[:album], :label_id => @label.id
      end
    end
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This label isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  

  private
  
  def create_new
    @label = Label.new(params[:label])
    @label.created_by = current_user.id
    
      respond_to do |format|
        if @label.save
          flash[:notice] = 'Label was successfully created.'
          if params[:track_id]
            format.html { redirect_to :controller => 'tracks',
                                      :action => 'check_added_label',
                                      :id => params[:track_id],
                                      :label => params[:label]}
          elsif params[:album_id]
            format.html { redirect_to :controller => 'albums',
                                      :action => 'check_added_label',
                                      :id => params[:album_id],
                                      :label => params[:label]}
          else
            format.html { redirect_to(@label) }
            format.xml  { render :xml => @label, :status => :created, :location => @label }
          end
        else
          format.html { render :action => "new" }
          format.xml  { render :xml => @label.errors, :status => :unprocessable_entity }
        end
      end
  end
  
  def get_tags
    @tags = Label.tag_counts(:order => ['RAND()'], :conditions => ["type = 'Label'"], :limit => 40 )
  end
  
end
