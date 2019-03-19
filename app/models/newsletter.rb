class Newsletter < ActiveRecord::Base
  
  validates_presence_of :text,
                        :message => "must not be empty."
  
  validates_presence_of :subject,
                        :message => "must not be empty."
                        
  has_friendly_id :subject,
    :use_slug => true,
    :max_length => 50,
    :approximate_ascii => true

  @@per_page = 20
  
  def self.find_for_sitemap(limit = 50000)
    find(:all, :select => 'id, updated_at', :order => 'updated_at DESC', :limit => limit)
  end
  
end
