class AlbumsController < ApplicationController
  before_filter :login_required, :except => [:index, :show, :tags]
  before_filter :get_tags, :except => [:tags, :show]
  
  require 'shared_controller.rb'
  include Shared
  
  layout 'music'
  
  auto_complete_for :album, :name
  
  before_filter :login_required,
                :except => [:index, :search, :search_results,
                            :auto_complete_search, :show]
  
  def index
   @page_title = "Albums"
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
      @albums = Album.paginate( :page => params[:page],
                                :order => 'music.name',
                                :joins => ["LEFT OUTER JOIN music AS labels ON (music.label_id = labels.id)"],
                                :include => ['artist', 'label', 'ratings'],
                                :conditions => cond )
    elsif @order == 'comments'
      @albums = Album.paginate( :page => params[:page],
                                :order => 'music.comments_count DESC, music.name',
                                :include => [:artist, :label, :ratings],
                                :joins => ["LEFT OUTER JOIN music AS labels ON (music.label_id = labels.id)"],
                                :conditions => cond)
    elsif @order == 'last_commented'
      @albums = Album.paginate( :page => params[:page],
                                :include => [:artist, :label, :ratings, :comments],
                                :joins => ["LEFT OUTER JOIN music AS labels ON (music.label_id = labels.id)"],
                                :order => 'comments.created_at DESC, music.name',
                                :conditions => cond )
    elsif @order == 'loves'
      @albums = Album.paginate( :page => params[:page],
                                :order => 'music.favourites_count DESC, music.name',
                                :include => [:artist, :label, :ratings],
                                :joins => ["LEFT OUTER JOIN music AS labels ON (music.label_id = labels.id)"],
                                :conditions => cond)
    elsif @order == 'rating'
      @albums = Album.paginate( :page => params[:page],
                                :include => [:artist, :label, :ratings],
                                :joins => ["LEFT OUTER JOIN music AS labels ON (music.label_id = labels.id)"],
                                :group => 'music.id',
                                :order => 'AVG(ratings.rating) DESC',
                                :conditions => cond )
    else
      @albums = Album.paginate( :page => params[:page],
                                :order => 'music.created_at DESC, music.name',
                                :joins => ["LEFT OUTER JOIN music AS labels ON (music.label_id = labels.id)"],
                                :conditions => cond,
                                :include => [:artist, :label, :ratings] )
    end  
    
    set_page_counts( Album.count(:all, :joins => ["LEFT OUTER JOIN music AS labels ON (music.label_id = labels.id)"], :conditions => cond), Music::per_page )
    
    respond_to do |format|
      format.html { render :action => 'index' }
      format.xml  { render :xml => @albums }
    end
  end
  
  def tags
    @page_title = "Albums Tags"
    @tags = Music.tag_counts( :conditions => ["type = 'Album'"] )
  end

  def show
      @album = Album.find(params[:id], :include => :tracks )
      @page_title = h(@album.name)
      @page_title += ' by ' +h(@album.artist.name) if @album.artist
      @page_title += ' on ' +h(@album.label.name) if @album.label
      @page_title += ', ' + @album.release_date.year.to_s if @album.release_date
      @tags = @album.tag_counts(  :conditions => ["type = 'Album'"]  )
      @rating_count = @album.ratings.size
      @ur = Rating.find(:first, :conditions => [ "user_id = ? AND rateable_id = ? AND rateable_type ='Musíc'", current_user, params[:id] ]) if current_user
      @love = @album.users.index( current_user ) if current_user
      @comments = Comment.paginate :page => params[:page],
                                  :include => ['report'],
                                  :conditions => ["commentable_id = ? AND commentable_type ='Music'", @album.id],
                                  :order => 'created_at DESC'
      @comment = Comment.new

      respond_to do |format|
        format.html # show.html.erb
        format.xml  { render :xml => @album }
    end
    rescue ActiveRecord::RecordNotFound
      flash[:notice] = "This album isn`t in the databse. It might have been removed."
      redirect_to :action => 'index'
  end
  
  def tag
    @tag = params[:id]
    @page_title = "Tag #{h @tag} on Albums"
    
    if params[:order] == 'name'
      tagged = Music.tagged_with( @tag, :on => :tags, :conditions => ["type = 'Album'"] ).by_name
      @albums = tagged.paginate( :page => params[:page] )
    elsif params[:order] == 'comments'
      tagged = Music.tagged_with( @tag, :on => :tags, :conditions => ["type = 'Album'"] ).by_comments
      @albums = tagged.paginate( :page => params[:page] )
    elsif params[:order] == 'last_commented'
      tagged = Music.tagged_with( @tag, :on => :tags, :conditions => ["type = 'Album'"] ).by_comments_date
      @albums = tagged.paginate( :page => params[:page] )
    elsif params[:order] == 'loves'
      tagged = Music.tagged_with( @tag, :on => :tags, :conditions => ["type = 'Album'"] ).by_loves
      @albums = tagged.paginate( :page => params[:page] )
    elsif params[:order] == 'rating'
      tagged = Music.tagged_with( @tag, :on => :tags, :conditions => ["type = 'Album'"] ).by_rating
      @albums = tagged.paginate( :page => params[:page] )
    else
      tagged = Music.tagged_with( @tag, :on => :tags, :conditions => ["type = 'Album'"] ).by_date
      @albums = tagged.paginate( :page => params[:page] )
    end
    
    set_page_counts( tagged.length, Music::per_page )
    
  end

  def new
    @page_title = "New Album"
    @album = Album.new(params[:album])
    @artist = Artist.find(params[:artist_id]) if params[:artist_id]
    @label = Label.find(params[:label_id]) if params[:label_id]
    @track = Track.find(params[:track_id]) if params[:track_id]

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @album }
    end
  end
  
  def check_new
    @intended = params[:album]
    unless @intended[:name].blank?
      equal = Album.find(:first, :conditions => [ "name = ?", @intended[:name] ])
      if equal.blank?
        @similars = Album.find(:all, :conditions => ["name like ?", '%' + @intended[:name] + '%'],
                                :order => 'name')
        create_new if @similars.empty?
      else
        notice = "This album is already in the database.<br>"
        notice += "<br>You can add it to a <em>label</em>." if equal.label_id.nil?
        notice += "<br>And you can add it to an <em>artist</em>." if equal.artist_id.nil?
        flash[:notice] = notice
        redirect_to :action => 'show', :id => equal.id
      end
    else
    redirect_to :action => 'new'
    end
  end
  
  def add_track
    @album = Album.find(params[:id])
    @page_title = "Add a track to #{h @album.name}"
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This album isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def check_added_track
    @album = Album.find(params[:id])
    track = Track.find(:first, :conditions => ["name = ?", params[:track][:name]]) if params[:track][:name]
    unless track.nil?
        track.albums << @album
        respond_to do |format|
            if @album.save
              flash[:notice] = "<em>#{track.name}</em> was successfully added to <em>#{@album.name}</em>."
              format.html { redirect_to :action => 'show', :id => @album }
              format.xml  { head :ok }
            else
              format.html { redirect_to :action => "add_track", :id => @album }
              format.xml  { render :xml => track.errors, :status => :unprocessable_entity }
            end
          end
    else
      if params[:track][:name].empty?
        redirect_to :action => 'add_track', :id => @album
      else
        flash[:notice] = "This track isn`t in the database yet. You can create it now."
        redirect_to :controller => 'tracks', :action => 'new', :track => params[:track], :album_id => @album.id
      end
    end
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This item isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end

  # GET /albums/1/edit
  def edit
    @album = Album.find(params[:id])
    @page_title = "Edit #{h @album.name}"
     rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This album isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end

  def create
    @page_title = "Create a new Album"
    if params[:choices].empty?
      create_new
    else
      album = Album.find(params[:choices])
      notice = "This album is already in the database.<br>"
      notice += "<br>You can add it to a <em>label</em>." if album.label_id.nil?
      notice += "<br>And you can add it to an <em>artist</em>." if album.artist_id.nil?
      flash[:notice] = notice
      redirect_to :action => 'show', :id => params[:choices]
    end
  end

  def add_label
    @album = Album.find(params[:id])
    @page_title = "Add a Label to #{h @album.name}"
     rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This album isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def check_added_label
    @album = Album.find(params[:id])
    label = Label.find(:first, :conditions => ["name = ?", params[:label][:name]])
    unless label.nil?
      @album.label_id = label.id
      flash[:notice] = 'Album was successfully updated.'
      
      ActiveRecord::Base.transaction do
        if @album.artist
          artist = @album.artist
          unless artist.labels.index(@album.label)
            artist.labels << @album.label
            flash[:notice] += "<br>And <em>#{@album.label.name}</em> was added to <em>#{@album.artist.name}`s</em> labels."
          end
        end
        respond_to do |format|
          if @album.save
            format.html { redirect_to(@album) }
            format.xml  { head :ok }
          else
            format.html { render :action => "edit" }
            format.xml  { render :xml => @album.errors, :status => :unprocessable_entity }
          end
        end
      end
      
    else
      if params[:label][:name].empty?
        redirect_to :action => 'add_label', :id => @album
      else
        flash[:notice] = "This label isn`t in the database yet. You can create it now."
        redirect_to :controller => 'labels', :action => 'new', :label => params[:label], :album_id => @album.id
      end
    end
     rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This album isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def add_artist
    @album = Album.find(params[:id])
    @page_title = "Add an Artist to #{h @album.name}"
     rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This album isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def check_added_artist
    @album = Album.find(params[:id])
    artist = Artist.find(:first, :conditions => ["name = ?", params[:artist][:name]]) if params[:artist][:name]
    unless artist.nil?
      @album.artist_id = artist.id
      respond_to do |format|
        if @album.save
          flash[:notice] = 'Album was successfully updated.'
          format.html { redirect_to(@album) }
          format.xml  { head :ok }
        else
          format.html { render :action => "edit" }
          format.xml  { render :xml => @album.errors, :status => :unprocessable_entity }
        end
      end
    else
      if params[:artist][:name].empty?
        redirect_to :action => 'add_artist', :id => @album
      else
        flash[:notice] = "This artist isn`t in the database yet. You can create him/her now."
        redirect_to :controller => 'artists', :action => 'new', :artist => params[:artist], :album_id => @album.id
      end
    end
     rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This item isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end

  def destroy
    @album = Album.find(params[:id])
    @album.destroy

    respond_to do |format|
      format.html { redirect_to(albums_url) }
      format.xml  { head :ok }
    end
     rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This album isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def enter_release_date
    @album = Album.find(params[:id])
    @page_title = "Enter Release Date for #{h @album.name}"
     rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This album isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def update_release_date
    @album = Album.find(params[:id])

    respond_to do |format|
      if @album.update_attribute( :release_date, Date.new(params[:date][:year].to_i) )
        flash[:notice] = 'Album was successfully updated.'
        format.html { redirect_to(@album) }
        format.xml  { head :ok }
      else
        format.html { render :action => "update_release_date" }
        format.xml  { render :xml => @album.errors, :status => :unprocessable_entity }
      end
    end
     rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This album isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  
  private
  
  def create_new
    @album = Album.new(params[:album])
    @album.artist_id = params[:artist_id]
    @album.label_id = params[:label_id]
    @album.created_by = current_user.id
      respond_to do |format|
        if @album.save
          flash[:notice] = "Album was successfully created."
          if params[:track_id]
            format.html { redirect_to :controller => 'tracks',
                                      :action => 'check_added_album',
                                      :id => params[:track_id],
                                      :album => params[:album]}
          elsif params[:label_id]
            format.html { redirect_to :controller => 'labels',
                                      :action => 'check_added_album',
                                      :id => params[:label_id],
                                      :album => params[:album]}
          elsif params[:artist_id]
            format.html { redirect_to :controller => 'artists',
                                      :action => 'check_added_album',
                                      :id => params[:artist_id],
                                      :album => params[:album]}
          else
            format.html { redirect_to(@album) }
            format.xml  { render :xml => @album, :status => :created, :location => @album }
          end
        else
          flash[:notice] = "There was a problem creating the item. Please try again."
          format.html { render :action => "new" }
          format.xml  { render :xml => @album.errors, :status => :unprocessable_entity }
        end
    end
  end
  
  def get_tags
    @tags = Music.tag_counts( :order => ['RAND()'], :conditions => ["type = 'Album'"], :limit => 40 )
  end

end
