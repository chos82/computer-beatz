class Topic < ActiveRecord::Base
  
  belongs_to :group
  has_many :news_messages, :foreign_key => 'thread_id', :dependent => :destroy
  belongs_to :user
  
  validates_presence_of :title,
                        :message => "must not be empty."
                        
  @@per_page = 20
  
  has_friendly_id :title,
    :use_slug => true,
    :max_length => 50,
    :approximate_ascii => true,
    :reserved_words => ["index", "new", 'news_messages']
  
  def self.find_for_sitemap(limit = 50000)
    find(:all, :select => 'id, updated_at, group_id', :order => 'updated_at DESC', :limit => limit)
  end
  
end
