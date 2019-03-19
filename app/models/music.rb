class Music < ActiveRecord::Base
  set_table_name 'music'
  
  #has_and_belongs_to_many :users, :join_table => 'music_users', :after_add => :increment_favourites_counter
  has_many :favourites, :as => :favourizable, :dependent => :destroy
  has_many :users, :through => :favourites
  has_many :comments, :as => :commentable, :dependent => :destroy
  belongs_to :creator, :class_name => 'User', :foreign_key => 'created_by', :counter_cache => 'no_items'
  has_one :report, :as => :reportable, :dependent => :destroy
  
  named_scope :by_date, :order => "created_at DESC"
  named_scope :by_rating, :include => 'ratings', :group => 'music.id', :order => 'AVG(ratings.rating) DESC'
  named_scope :by_loves, :order => 'favourites_count DESC, music.name'
  named_scope :by_comments_date, :include => 'comments', :order => 'comments.created_at DESC, music.name'
  named_scope :by_comments, :order => 'comments_count DESC, music.name' 
  named_scope :by_name, :order => 'music.name'
  
  acts_as_rateable
  
  acts_as_taggable_on :tags
  
  has_friendly_id :name,
    :use_slug => true,
    :max_length => 50,
    :approximate_ascii => true,
    :reserved_words => %w{index new make_favourite remove_from_favourites add_comment
                          manage_tags post_tags auto_complete_search auto_complete_tags
                          advanced_form auto_complete_label auto_complete_artist
                          auto_complete_track auto_complete_album auto_complete_tag_search
                          search advanced_search tags favourized_by member remove_from_favourites
                          add_comment manage_tags post_tags taggers edit_tags similar}
  
  cattr_reader :per_page
  @@per_page = 15
            
  RELEASE_CONNECTORS = [['and younger', 0],
                        ['and older',   1]]
  
  HUMANIZED_ATTRIBUTES = {
    :www => 'Homepage'
  }

  def self.human_attribute_name(attr)
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end 

  
  validates_presence_of :name
  #validates_uniqueness_of :name,
  #                        :message => "is already in the database."
  validates_format_of :www,
                      :with => /^(www\.)?.+\.+[a-z]{2,10}(\/[^\/\\]+)*\/?$/,
                      :message => "has to be a valid www address.",
                      :unless => Proc.new { |u| u.www.blank? }
                      
  validates_inclusion_of :type,
                         :in => %w{ Label Artist Track Album Mix },
                         :message => "could not be created."
                         
  def increment_favourites_counter(user)
    favourites_count += 1
  end
  
  def self.find_for_sitemap(limit = 50000)
    find(:all, :select => 'id, updated_at, type', :order => 'updated_at DESC', :limit => limit)
  end
  
  def tagging_date
    if first_time_tagged
      (Time.parse first_time_tagged).to_date
    else
      nil
    end
  end

  def tags_by(user)
    Tag.find(:all, :include => [:taggings], :conditions => ["taggings.tagger_id = ? AND taggings.taggable_id = ?", user, id])
  end
                      
  #gets a query string, seperates it by means of +, -, \s (, in case of tags) and constructs a find query
  #where the conditions match the input query string
  #returns false, if type is not in TYPES
  #if :intersect_tags == true => result instances will match both, :query and :tags
  #otherwise, results might match only the query string or the tags
  #CURRENTLY only for the type music is used in the controllers
  def self.search( arg = {} )
    arg.assert_valid_keys :query, :offset, :limit,
                          :order, :release_connector, 
                          :release_date, :type, :count?
                          
    cond = ['']                          
    cond = make_conditions( cond, arg[:query], "music.name" )
    
    options = make_options( arg[:order], ['tags'] )
    
    cond[0] += " OR "    
    
    make_conditions( cond, arg[:query], "tags.name" )
    
    case arg[:type]
      when 'music'
        objects = find( :all, :conditions => cond, :include => options[:include], :group => options[:group], :offset => arg[:offset], :limit => arg[:limit], :order => options[:order] )
        count = count( :all, :conditions => cond, :include => options[:include], :group => options[:group] ) if arg[:count?]
      when 'labels'
        objects = Label.find( :all, :conditions => cond, :include => options[:include], :group => options[:group], :offset => arg[:offset], :limit => arg[:limit], :order => options[:order] )
        count = Label.count( :all, :conditions => cond, :include => options[:include], :group => options[:group] ) if arg[:count?]
      when 'artists'
        objects = Artist.find( :all, :conditions => cond, :include => options[:include], :group => options[:group], :offset => arg[:offset], :limit => arg[:limit], :order => options[:order])
        count = Artist.count( :all, :conditions => cond, :include => options[:include], :group => options[:group] ) if arg[:count?]
      when 'albums'
        objects = Album.find( :all, :conditions => cond, :include => options[:include], :group => options[:group], :offset => arg[:offset], :limit => arg[:limit], :order => options[:order])
        count = Album.count( :all, :conditions => cond, :include => options[:include], :group => options[:group] ) if arg[:count?]
      when 'tracks'
        unless arg[:release_date].blank?
          case arg[:release_connector]
            when '0'
              arg[:release_connector] = '>='
            when '1'
              arg[:release_connector] = '<='
            else
              arg[:release_connector] = '='
          end
          cond[0] += " AND " if arg[:query] != '*' && !arg[:query].blank?
          cond[0] += "(music.release_date #{arg[:release_connector]} ? AND music.release_date IS NOT NULL)"
          cond << Date.new( arg[:release_date].to_i )
        end
        objects = Track.find( :all, :conditions => cond, :include => options[:include], :group => options[:group], :offset => arg[:offset], :limit => arg[:limit], :order => options[:order] )
        count = count( :all, :conditions => cond, :include => options[:include], :group => options[:group] ) if arg[:count?]
    end
    
    {:objects => objects, :count => count}
  end
  
  def self.search_advanced( arg = {} )
    arg.assert_valid_keys :label, :artist, :album, :track, :tags, :type,
                          :release_date, :release_connector, :license,
                          :order, :offset, :limit

    cond = ['']
    include = !arg[:tags].blank? ? [:tags] : []
    join = []
    
    unless arg[:label].blank?
      ali = (arg[:type] == 'labels') ? "music.name" : "labels_music.name"
      make_conditions( cond, arg[:label], ali )
      if arg[:type] == 'artists'
        join << :labels
      else
        join << :label
      end
    end
    unless arg[:artist].blank?
      cond[0] += " AND " unless cond[0].empty?
      ali = (arg[:type] == 'artists') ? "music.name" : "artists_music.name"
      make_conditions( cond, arg[:artist], ali )
      join << :artists
    end
    unless arg[:album].blank?
      cond[0] += " AND " unless cond[0].empty?
      ali = arg[:type] == 'albums' ? "music.name" : "albums_music.name"
      make_conditions( cond, arg[:album], ali )
      join << :albums
    end
    unless arg[:track].blank?
      cond[0] += " AND " unless cond[0].empty?
      ali = arg[:type] == 'tracks' ? "music.name" : "tracks_music.name"
      make_conditions( cond, arg[:track], ali )
      join << :tracks
    end
    unless arg[:tags].blank?
      cond[0] += " AND " unless cond[0].empty?
      make_conditions( cond, arg[:tags], "tags.name" )
    end
    
    case arg[:type]
      #when 'music'
      #  options = make_options( arg[:order], include )
      #  objects = find( :all, :conditions => cond, :include => options[:include], :group => options[:group], :offset => arg[:offset], :limit => arg[:limit], :order => options[:order] )
      #  count = count( :all, :conditions => cond, :include => options[:include], :group => options[:group] )
      when 'labels'
        unless arg[:license].blank? || arg[:license] == 'both'
          cond[0] += " AND music.license = ?"
          cond << arg[:license]
        end
        options = make_options( arg[:order], include )
        objects = Label.find( :all, :select => " DISTINCT music.*", :conditions => cond, :include => options[:include], :joins => join, :group => options[:group], :offset => arg[:offset], :limit => arg[:limit], :order => options[:order] )
        count = Label.count( :all, :conditions => cond, :include => options[:include], :joins => join, :group => options[:group] )
      when 'artists'
#        join << :labels unless arg[:label].blank?
        options = make_options( arg[:order], include )
        objects = Artist.find( :all, :select => " DISTINCT music.*", :conditions => cond, :include => options[:include], :joins => join, :group => options[:group], :offset => arg[:offset], :limit => arg[:limit], :order => options[:order])
        count = Artist.count( :all, :conditions => cond, :include => options[:include], :joins => join, :group => options[:group] )
      when 'tracks', 'albums'
        unless arg[:license].blank? || arg[:license] == 'both'
          cond[0] += " AND labels_music.license = ?"
          cond << arg[:license]
        end
#        join << :label unless arg[:label].blank? && arg[:license] == 'both'
#        join << :artist unless arg[:artist].blank?
        options = make_options( arg[:order], include )
        unless arg[:release_date].blank?
          case arg[:release_connector]
            when '0'
              arg[:release_connector] = '>='
            when '1'
              arg[:release_connector] = '<='
            else
              arg[:release_connector] = '='
          end
          cond[0] += " AND " unless cond[0].blank?
          cond[0] += "music.release_date #{arg[:release_connector]} ? AND music.release_date IS NOT NULL"
          cond << Date.new( arg[:release_date].to_i )
        end
        if arg[:type] == 'albums'
#          join << :tracks unless arg[:track].blank?
          objects = Album.find( :all, :select => " DISTINCT music.*", :conditions => cond, :include => options[:include], :joins => join, :group => options[:group], :offset => arg[:offset], :limit => arg[:limit], :order => options[:order] )
          count = Album.count( :all, :conditions => cond, :joins => join, :include => options[:include], :group => options[:group] )
        else # looking for a track
#          join << :albums unless arg[:album].blank?
          objects = Track.find( :all, :select => " DISTINCT music.*", :conditions => cond, :include => options[:include], :joins => join, :group => options[:group], :offset => arg[:offset], :limit => arg[:limit], :order => options[:order] )
          count = Track.count( :all, :conditions => cond, :joins => join, :include => options[:include], :group => options[:group] )
        end
    end
    {:objects => objects, :count => count}
  end
    
  def rated_by_user?(user)
    res = false
    unless user == nil
      self.ratings.each{|r|
        res = true if r.user_id == user.id
      }
    end
    res
  end
  
  
  private
  
  def self.make_conditions( cond, query, attr_name = 'music' )
    tokens = []
    connectors = []
    inner_not = []
    cond[0] += '('
    iqcre = /(\s|\+|#|,|\|)/
    while query =~ iqcre do
      pos = (query =~ iqcre)
      unless pos == 0
        connectors << classify_connector( query[pos, 1] )
        tokens << query.slice(0...pos)
        query = query.slice((pos + 1)..-1)
      else
        if query[0, 1] == '#' #überflüssig?
          inner_not << 'NOT'
          query = query.slice(1..-1)
          p = query =~ iqcre
          end_con = p ? p-1 : -1
          unless end_con == -1
            connectors << classify_connector( query[(end_con +1), 1] )
            query = query.slice((end_con + 2)..-1)
          end
        end
      end
      query.strip!
    end
    tokens << query
    tokens.collect! {|c| '%' + c + '%'}
    #tokens.collect! {|c| c.strip}
    
    #construct the conditions array
     for i in 0...tokens.size do
      cond[0] +=  "#{attr_name} #{inner_not[i]} LIKE ? #{connectors[i]}" 
      cond[0] += ' ' unless i == (tokens.size - 1)
      cond << tokens[i]
    end
    cond[0] += ')'
    cond
  end
  
  def self.classify_connector(char)
    case char
      when /[\+\s,]/
        'AND'
      when '#'
        'AND NOT'
      when '|'
        'OR'
    end
  end
  
  def self.make_options( order, include = [] )
    res = Hash.new
    res[:include] = include
    if order == 'comments'
      res[:order] = 'music.comments_count DESC, music.name'
    elsif order == 'last_commented'
      res[:order] = 'comments.created_at DESC, music.name'
      res[:include] << 'comments'
    elsif order == 'loves'
      res[:order] = 'music.favourites_count DESC, music.name'
    elsif order == 'rating'
      res[:order] = 'AVG(ratings.rating) DESC, music.name'
      res[:include] << 'ratings'
      res[:group] = 'music.id'
    elsif order == 'newest'
      res[:order] = 'music.created_at DESC, music.name'
    else
      res[:order] = 'music.name ASC'
    end
    res
  end
  
end