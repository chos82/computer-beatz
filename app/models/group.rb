class Group < ActiveRecord::Base
  
  has_many :members, :dependent => :destroy
  has_many :invitations, :dependent => :destroy
  has_many :users, :through => :members, :uniq => true
  has_many :topics, :dependent => :destroy
  belongs_to :admin, :class_name => 'User', :foreign_key => 'admin'
  has_many :news_messages, :through => :topics, :dependent => :destroy
  
  @@per_page = 12
  
  has_attached_file :logo,
      :styles => {
      :thumb=> "40x40#",
      :small  => "124x124>",
      :original => "250x250>"},
      :url => "/system/:class/:attachment/:id/:style_:basename.:extension",
      :path => "/:rails_root/../../shared/system/:class/:attachment/:id/:style_:basename.:extension",
      :default_url => "/:class/:attachment/missing_:style.png"
      
  validates_attachment_content_type :logo, :content_type =>[ 'image/gif', 'image/png', 'image/x-png', 'image/jpeg', 'image/pjpeg', 'image/jpg' ]
  validates_attachment_size :logo, :less_than => 3.megabytes
  
  validates_uniqueness_of :title
  
  validates_presence_of :description,
                        :message => "must not be empty."
  validates_length_of :description,
                      :maximum => 3000,
                      :message => "must be 3000 characters or less."
                      
  validates_presence_of :title,
                        :message => "must not be empty."
  validates_length_of :title,
                      :maximum => 255,
                      :message => "must be 255 characters or less."
                      
  has_friendly_id :title,
    :use_slug => true,
    :max_length => 50,
    :approximate_ascii => true,
    :reserved_words => ["index", "new", 'search', 'auto_complete_search',
                        'auto_complete_reciever', 'give_away_form',
                        'give_away', 'topics']
  
  def self.find_for_sitemap(limit = 50000)
    find(:all, :select => 'id, updated_at', :order => 'updated_at DESC', :limit => limit)
  end
  
  def self.search( args )
    args.assert_valid_keys :query, :order,
                          :count,
                          :limit, :offset
                          
    cond = make_conditions(args[:query])
    
    if args[:order] == 'messages'
      args[:order] = "(SELECT COUNT(*) FROM ( groups JOIN news_messages ON (groups.id = news_messages.group_id) ) GROUP BY groups.id)DESC"
    elsif args[:order] == 'members'
      args[:order] = "(SELECT COUNT(*) FROM ( groups JOIN members ON (groups.id = members.group_id) ) GROUP BY groups.id)DESC"
    elsif args[:order] == 'name'
      args[:order] = 'titel ASC'
    else
      args[:order] = "news_messages.updated_at DESC"
      include = "news_messages"
    end
    
    objects = find( :all, :include => include, :conditions => cond, :order => args[:order], :limit => args[:limit], :offset => args[:offset] )
    count = count( :all, :include => include, :conditions => cond, :order => args[:order] ) if args[:count]
    
    {:objects => objects, :count => count}
  end
  
  private
  
  def self.make_conditions( query )
    cond = ['']
    if query == '*'
      return cond
    end
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
      cond[0] +=  "title #{inner_not[i]} LIKE ? #{connectors[i]}"
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

end
