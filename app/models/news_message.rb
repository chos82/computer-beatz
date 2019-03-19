class NewsMessage < ActiveRecord::Base
   
  belongs_to :sender, :class_name => 'User', :foreign_key => 'sender'
  belongs_to :topic, :foreign_key => 'thread_id', :touch => true, :counter_cache => true
  
  acts_as_ferret :fields => [:subject, :text, :topic_title]
  
  validates_presence_of :text,
                        :message => "must not be empty."
  validates_length_of :text,
                      :maximum => 10000,
                      :message => "must be 10000 characters or less."
                      
  validates_presence_of :subject,
                        :message => "must not be empty."
  validates_length_of :subject,
                      :maximum => 255,
                      :message => "must be 255 characters or less."
                      
  @@per_page = 15
  
  def self.find_for_sitemap(limit = 50000)
    find(:all, :select => ['id', 'updated_at'], :order => 'updated_at DESC', :limit => limit)
  end
  
  def visible?
    self.topic.goup.visible
  end
  
  def self.topic_title
    self.topic.title
  end
  
  #TODO: include those two methods for ferret search: derive model of search hit
  def self.group_title
    self.topic.group.title
  end
  
  def self.group_description
    self.topic.group.description
  end
  
end
