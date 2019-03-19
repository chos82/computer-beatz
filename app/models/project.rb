class Project < ActiveRecord::Base
  
  has_many :users, :through => :project_memberships
  has_many :releases, :dependent => :destroy
  has_many :project_memberships, :dependent => :destroy
  has_many :comments, :as => :commentable, :dependent => :destroy
  
  acts_as_rateable
  
  @@per_page = 10
  
  has_attached_file :logo,
      :styles => {
      :thumb=> "40x40#",
      :small  => "124x124>",
      :normal => "250x250>"},
      :url => "/system/:class/:attachment/:id/:style_:basename.:extension",
      :path => "/:rails_root/../../shared/system/:class/:attachment/:id/:style_:basename.:extension",
      :default_url => "/:class/:attachment/missing_:style.png"
      
  validates_attachment_content_type :logo,
    :content_type =>[ 'image/gif', 'image/png', 'image/x-png', 'image/jpeg', 'image/pjpeg', 'image/jpg' ],
    :if => Proc.new { |p| !p.logo.blank? }
  validates_attachment_size :logo, :less_than => 3.megabytes,
    :if => Proc.new { |p| !p.logo.blank? }
  
  validates_uniqueness_of :name
  
  validates_presence_of :description,
                        :message => "must not be empty."
                        
  validates_presence_of :license,
                        :message => "must be set."
                      
  validates_presence_of :name,
                        :message => "must not be empty."
                        
  validates_length_of :name,
                      :maximum => 255,
                      :message => "must be 255 characters or less."
  
  validates_inclusion_of :license,
    :in => %w{ by by-sa by-nd by-nc by-nc-sa by-nc-nd },
    :message => "is not valid."
    
  has_friendly_id :name,
    :use_slug => true,
    :max_length => 50,
    :approximate_ascii => true,
    :reserved_words => %w{index new invite member audio
                          logo delete_comment pending}
  
  def self.find_for_sitemap(limit = 50000)
    find(:all, :select => 'id, updated_at', :order => 'updated_at DESC', :limit => limit)
  end
  
  def echo_license
    out = 'Creative Commons '
    case license
      when 'by'
        out += 'Attribution'
      when 'by-sa'
        out += 'Attribution-ShareAlike'
      when 'by-nd'
        out += 'Attribution-NoDerivs'
      when 'by-nc'
        out += 'Attribution-NonCommercial'
      when 'by-nc-sa'
        out += 'Attribution-NonCommercial-ShareAlike'
      when 'by-nc-nd'
        out += 'Attribution-NonCommercial-NoDerivs'
    end
  end
  
  def pending_releases
    @pending_releases = Release.count(:conditions => ["state = 'uploaded' AND project_id = ?", self.id])
  end
  
  def declined_releases
    @declined_releases = Release.count(:conditions => ["state = 'declined' AND project_id = ?", self.id])
  end
  
  def published_releases
    @published_releases = Release.count(:conditions => ["state = 'released' AND project_id = ?", self.id])
  end
  
  def was_declined_before?(user)
    #TODO: do it!
    memberships = ProjectMembership.find(:all, :conditions => ['project_id = ?', self.id])
    also_member = Project.find(:all,
              :joins => [:releases, :project_memberships],
              :conditions => ["project_memberships.user_id = ? AND NOT releases.state = 'declined' AND NOT projects.id = ?", user.id, self.id],
              :group => ['projects.id'],
              :having => ["COUNT(releases.id) >= 3"])
    return false if also_member.empty?
    also_member.each do |am|
      return false unless am.project_memberships == memberships
    end
    return true
  end
  
  def has_quota?(user)
    #do not call methods here - queries are cashed!
    pending = Release.count(:conditions => ["state = 'uploaded' AND project_id = ?", self.id])
    declined = Release.count(:conditions => ["state = 'declined' AND project_id = ?", self.id])
    published = Release.count(:conditions => ["state = 'released' AND project_id = ?", self.id])
     !was_declined_before?(user) && 
     pending < 3 &&
     (declined < 3 ||
     published > 0)
  end
  
  def is_member?(user)
    return true if users.include? user
    false
  end
  
  def active_members
    User.find(:all, :include => ['project_memberships'], :conditions => ["project_memberships.status = 'active' AND project_memberships.project_id = ?", self.id])
  end

end
