class MusicController < ApplicationController
  require 'shared_controller.rb'
  include Shared
  
  layout 'music'
  
  before_filter :login_required, :only => [:make_favourite, :remove_from_favourites, :add_comment, :rate, :manage_tags, :post_tags]
  before_filter :get_tags, :except => [:tags, :show]
  
  def index
    @page_title = "All music"
    @tags = Music.tag_counts(:limit => 40)

    if params[:order] == 'name'
      @music = Music.paginate( :page => params[:page], :order => 'name', :include => [:ratings] )
    elsif params[:order] == 'comments'
      @music = Music.paginate( :page => params[:page], :order => 'comments_count DESC, name', :include => [:ratings] )
    elsif params[:order] == 'last_commented'
      @music = Music.paginate( :page => params[:page], :include => [:ratings, :comments], :order => 'comments.created_at DESC, name' )
    elsif params[:order] == 'loves'
      @music = Music.paginate( :page => params[:page], :order => 'favourites_count DESC, name', :include => [:ratings] )
    elsif params[:order] == 'rating'
      @music = Music.paginate( :page => params[:page], :include => 'ratings', :group => 'music.id', :order => 'AVG(ratings.rating) DESC, name' )
    else
      @music = Music.paginate( :page => params[:page], :order => 'music.created_at DESC, music.name', :include => [:ratings])
    end  
    
    set_page_counts( Music.count(:all), Music::per_page )

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @music }
    end
  end
  
  def tags
    @page_title = "All tags"
    @tags = Music.tag_counts
  end
  
  def tag
    @tag = params[:id]
    @page_title = "Tag #{h @tag}"
    
    if params[:order] == 'name'
      tagged = Music.tagged_with( @tag, :on => :tags ).by_name
      @music = tagged.paginate( :page => params[:page] )
    elsif params[:order] == 'comments'
      tagged = Music.tagged_with( @tag, :on => :tags ).by_comments
      @music = tagged.paginate( :page => params[:page] )
    elsif params[:order] == 'last_commented'
      tagged = Music.tagged_with( @tag, :on => :tags ).by_comments_date
      @music = tagged.paginate( :page => params[:page] )
    elsif params[:order] == 'loves'
      tagged = Music.tagged_with( @tag, :on => :tags ).by_loves
      @music = tagged.paginate( :page => params[:page] )
    elsif params[:order] == 'rating'
      tagged = Music.tagged_with( @tag, :on => :tags ).by_rating
      @music = tagged.paginate( :page => params[:page] )
    else
      tagged = Music.tagged_with( @tag, :on => :tags ).by_date
      @music = tagged.paginate( :page => params[:page] )
    end
    
    set_page_counts( tagged.length, Music::per_page )
  end
  
  def search
    @query = syntax_checker params[:search][:query] if params[:search]
    unless @query
      flash[:error] = "Query '#{h params[:search][:query]}' is not valid syntax." if params[:search]
      redirect_to music_index_path
    else
    
    unless params[:page]
      page = 1
    else
      page = params[:page]
    end
    
    @results = WillPaginate::Collection.create(page, Music::per_page) do |pager|
      result = Music.search( :query => @query,
                             :type => 'music',
                             :order => params[:order],
                             :offset => pager.offset,
                             :limit => pager.per_page,
                             :count? => true)
      #partial_res = result[pager.offset...(pager.offset + pager.per_page)]
      # inject the result array into the paginated collection:
      pager.replace(result[:objects])
      
      unless pager.total_entries
        # the pager didn't manage to guess the total count, do it manually
        pager.total_entries = result[:count]
      end
      set_page_counts( pager.total_entries, pager.per_page )
    end
    end
  end
  
  def advanced_form
    @page_title = "Search for music"
  end
  
  def advanced_search
    @page_title = "Search results"
    unless params[:query]
      redirect_to :action => 'advanced_form'
      return
    end
    @label = advanced_syntax_checker params[:query][:label]
    @artist = advanced_syntax_checker params[:query][:artist]
    @album = advanced_syntax_checker params[:query][:album]
    @track = advanced_syntax_checker params[:query][:track]
    @release_date = params[:date][:year]
    @release_connector = params[:query][:release_connector]
    @tags = advanced_syntax_checker params[:query][:tags]
    @order = params[:order]
    @license = params[:query][:license]
    @type = params[:query][:type]
    @type = 'music' if !( @type == 'artists' || @type == 'albums' || @type == 'labels' || @type == 'tracks')
    if( ( @label.blank? &&
          @artist.blank? && 
          @track.blank? && 
          @tags.blank? && 
          @album.blank? && 
        @release_date.blank? && @tags.blank? ) || 
         !(@label && @artist && @track && @album && @tags) || 
          (!@release_connector.blank? && @release_date.blank?) || 
          ( (@type == 'music' || @type == 'artists') && 
        @license != 'both' ) )
      date = @release_date.blank? ? '<em>all</em>' : @release_date
      connector = ''
      unless @release_connector.blank?
        connector = Music::RELEASE_CONNECTORS[@release_connector.to_i][0] unless @release_date.blank?
      else
        connector = 'exactly' unless @release_date.blank?
      end
      flash[:error] = "The query has no valid syntax.<br />"+
        "<div class=\"indent\">Label: #{params[:query][:label]}<br />"+
        "Artist: #{params[:query][:artist]}<br />"+
        "Album: #{params[:query][:album]}<br />"+
        "Track: #{params[:query][:track]}<br />"+
        "Release date: #{date} #{connector}<br/>"+
        "Tags: #{params[:query][:tags]}</div>"
      redirect_to :action => 'advanced_form'
    else
      page = params[:page]
      page = 1 unless page
      @results = WillPaginate::Collection.create(page, Music.per_page) do |pager|
        result = Music.search_advanced( :label => @label, :artist => @artist, :album => @album,
                                        :track => @track, :tags => @tags,
                                        :type => @type, :release_date => @release_date,
                                        :release_connector => @release_connector,
                                        :license => @license,
                                        :order => @order,
                                        :limit => pager.per_page,
                                        :offset => pager.offset)
        #partial_res = result[pager.offset...(pager.offset + pager.per_page)]
        # inject the result array into the paginated collection:
        pager.replace(result[:objects])

        unless pager.total_entries
          # the pager didn't manage to guess the total count, do it manually
          pager.total_entries = result[:count]
        end
        set_page_counts( pager.total_entries, pager.per_page )
      end
    end
  end
  
  def auto_complete_label
    query = params[:query][:label] if params[:query] && params[:query][:label]
    @auto_results = []
    if query && syntax_checker(query)
      @auto_results = Music.search(:query => query, :type => 'labels', :limit => 10)[:objects]
    end
    render :partial => 'auto_results'
  end
  
  def auto_complete_artist
    query = params[:query][:artist] if params[:query] && params[:query][:artist]
    @auto_results = []
    if query && syntax_checker(query)
      @auto_results = Music.search(:query => query, :type => 'artists', :limit => 10)[:objects]
    end
    render :partial => 'auto_results'
  end
  
  def auto_complete_album
    query = params[:query][:album] if params[:query] && params[:query][:album]
    @auto_results = []
    if query && syntax_checker(query)
      @auto_results = Music.search(:query => query, :type => 'albums', :limit => 10)[:objects]
    end
    render :partial => 'auto_results'
  end
  
  def auto_complete_track
    query = params[:query][:track] if params[:query] && params[:query][:track]
    @auto_results = []
    if query && syntax_checker(query)
      @auto_results = Music.search(:query => query, :type => 'tracks', :limit => 10)[:objects]
    end
    render :partial => 'auto_results'
  end
  
  def auto_complete_search
    query = params[:search][:query] if params[:search] && params[:search][:query]
    @auto_results = []
    if query && syntax_checker(query)
      @auto_results = Music.search(:query => query, :type => 'music', :limit => 10)[:objects]
    end
    render :partial => 'auto_results'
  end
  
  def auto_complete_tags
    query = params[:tag][:text] if params[:tag] && params[:tag][:text]
    @auto_results = []
    if query
      @auto_results = Tag.find(:all, :conditions => ["name LIKE ?", '%' + query + '%'], :limit => 10)
    end
    render :partial => 'tag_auto_results'
  end
  
  def auto_complete_tag_search
    query = params[:query][:tags] if params[:query] && params[:query][:search]
    @auto_results = []
    if query
      @auto_results = Tag.find(:all, :conditions => ["name LIKE ?", '%' + query + '%'], :limit => 10)
    end
    render :partial => 'tag_auto_results'
  end
  
  def make_favourite
    @item = Music.find(params[:id])
    @item.users << current_user
    @item = Music.find(params[:id])
    @love = true
    respond_to do |format|
      format.js
    end 
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This item isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def remove_from_favourites
    @item = Music.find(params[:id])
    Favourite.destroy_all(["favourizable_type ='Music' AND favourizable_id = ? AND user_id = ?", @item.id, current_user])
    @love = false
    respond_to do |format|
      format.js
    end
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This item isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def favourized_by
    @music = Music.find( params[:id] )
    @page_title = "People who like #{h @music.name}"
    @users = User.paginate( :page => params[:page],
                            :include => ['favourites'],
                            :conditions => [ "favourites.favourizable_type = 'Music' AND favourites.favourizable_id = ?", @music.id ] )
    count = User.count( :all, :include => ['favourites'],
                        :conditions => [ "favourites.favourizable_type = 'Music' AND favourites.favourizable_id = ?", @music.id ] )
                          
    set_page_counts count, @users::per_page
     rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This item isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def rate
    @item = Music.find(params[:id])
    old_rating = Rating.find(:first, :conditions => [ "user_id = ? AND rateable_id = ?", current_user.id, @item.id ])
    unless old_rating
      @ur = Rating.new(:rating => params[:rating], :user_id => current_user.id, :rateable_type => @item.type)
      @item.add_rating @ur
      @rating_count = @item.ratings.size
      respond_to do |format|
        format.js
      end
    end
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This item isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def add_comment
    @comment = Comment.new(params[:comment])
    @comment.user = current_user
    entry = Music.find(params[:id])
    @comment.commentable = entry
    
    ActiveRecord::Base.transaction do
      respond_to do |format|
        if @comment.save
          flash[:notice] = 'Comment was successfully created.'
          format.html { redirect_to(:controller => get_controller_from_type(entry), :action => 'show', :id => params[:id]) }
          format.xml  { render :xml => @comment, :status => :created, :location => @comment }
        else
          format.html { redirect_to :controller => get_controller_from_type(entry), :action => "show", :id => params[:id] }
          format.xml  { redirect_to :xml => @comment.errors, :status => :unprocessable_entity }
        end
      end
    end
  end
  
  def manage_tags
    @item = Music.find(params[:id])
    manipulate_tags(:controller => get_controller_from_type(@item), :action => "show", :id => params[:id])
  end
  
  def edit_tags
    manipulate_tags(:controller => :users, :action => 'tagged', :id => current_user)
  end
  
  def post_tags
    @item = Music.find(params[:id])
    update_tags(:controller => get_controller_from_type(@item), :action => 'show', :id => params[:id])
  end
  
  def save_tags
    update_tags(:controller => :users, :action => 'tagged', :id => current_user)
  end
  
  def taggers
    @item = Music.find(params[:id])
    @page_title = "People who tagged #{h @item.name}"
    @taggers = User.paginate(:all,
                         :page => params[:page],
                         :select => ['DISTINCT users.*'],
                         :joins => ['LEFT OUTER JOIN taggings ON taggings.tagger_id = users.id'],
                         :conditions => ["taggings.taggable_id = ?", @item],
                         :order => ['users.login ASC'])
    set_page_counts( User.count(:joins => ['LEFT OUTER JOIN taggings ON taggings.tagger_id = users.id'],
                         :conditions => ["taggings.taggable_id = ?", @item]), User::per_page )
  end
  
  
  private
  
  def get_controller_from_type( item )
    if item.class == Artist
      controller = 'artists'
    elsif item.class == Label
      controller = 'labels'
    elsif item.class == Track
      controller = 'tracks'
    elsif item.class == Album
      controller = 'albums'
    else
      flash[:error] = "An internal redirection error occured, sorry."
      controller = 'music'
    end
    controller
  end
  
  def manipulate_tags(redirect)
    @item = Music.find(params[:id])
    @tags = @item.tags_from(current_user)
    respond_to do |format|
      if request.xhr?
        @popular_tags = @item.tag_counts(:order => [:order], :limit => 10)
        @popular_tags.delete_if{ |i| @tags.include? i.name }
        @recommended_tags = Tag.find(:all,
                                     :include => [:taggings],
                                     :conditions => ["taggings.tagger_id = ?", current_user],
                                     :group => ["tags.id"],
                                     :limit => 10)
        @recommended_tags.delete_if{ |i| @tags.include? i.name }
        format.js
      end
      format.html {redirect_to redirect}
    end
  end
  
  def update_tags(redirect)
    @item = Music.find(params[:id])
    #@item.tag_list.add( params[:tag][:text], {:parse => true} )
    tag_text = params[:tag][:text].gsub(/\s+/, ' ')
    if current_user.tag(@item, :with => tag_text, :on => :tags)
      flash[:notice] = "Tag(s) successfully updated."
    else
      flash[:error] = "Sorry, there was a problem with updating your tag(s)."
    end
    redirect_to(redirect)
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This item isn`t in the databse. It might have been removed."
        redirect_to music_index_path
  end
  
  def get_tags
    @tags = Music.tag_counts(:order => ['RAND()'], :limit => 40 )
  end

end
