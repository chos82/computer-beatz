class Release < ActiveRecord::Base
  require 'mp3info'
  
  belongs_to :project, :touch => true
  has_many :favourites, :as => :favourizable, :dependent => :destroy
  has_many :users, :through => :favourites
  has_many :comments, :as => :commentable, :dependent => :destroy
  
  acts_as_rateable
  
  has_attached_file :cover,
      :styles => {
      :thumb=> {:geometry => "40x40#",
          :processors => [:thumbnail, :cover_thumb]},
      :normal  => {:geometry => "250x250>",
        :processors => [:thumbnail, :cover_canvas_normal, :cover_watermark_normal]},
      :original => {:geometry => "800x800>",
        :processors => [:thumbnail, :cover_canvas_original, :cover_watermark_original]}
      },
      :url => "/system/:class/:attachment/:id/:style_:basename.:extension",
      :path => "/:rails_root/../../shared/system/:class/:attachment/:id/:style_:basename.:extension",
      :default_url => "/:class/:attachment/missing_:style.png"
  has_attached_file :audio,
      :path => "/:rails_root/../../shared/system/:attachment/computer-beatz_:name.:extension",
      :url => "/system/:attachment/computer-beatz_:name.:extension",
      :processors => [:mp3_tags]
     
  validates_attachment_content_type :cover,
    :content_type =>[ 'image/gif', 'image/png', 'image/x-png', 'image/jpeg', 'image/pjpeg', 'image/jpg' ],
    :if => Proc.new { |r| !r.cover.blank? }
  validates_attachment_size :cover, :less_than => 3.megabytes,
      :if => Proc.new { |r| !r.cover.blank? }
      
  validates_attachment_content_type :audio, :content_type => [ 'application/mp3', 'application/x-mp3', 'audio/mpeg', 'audio/mp3' ],
      :if => Proc.new { |r| !r.audio.blank? }
  validates_attachment_size :audio, :less_than => 12.megabytes,
      :if => Proc.new { |r| !r.audio.blank? }
  
  #validates_attachment_presence :audio,
  #  :unless => Proc.new { |r| r.no_audio }
  
  validate :correct_bitrate

  validates_uniqueness_of :name
                      
  validates_presence_of :name,
                        :message => "must not be empty."
                        
  validates_length_of :name,
                      :maximum => 255,
                      :message => "must be 255 characters or less."
                      
  validates_inclusion_of :state,
    :in => %w{ uploaded released declined },
    :message => "is not valid."
    
  has_friendly_id :name,
    :use_slug => true,
    :max_length => 50,
    :approximate_ascii => true
    
  before_create :set_mp3_tags
                      
  #attr_accessible :name, :description
  
  def self.find_for_sitemap(limit = 50000)
    find(:all, :select => 'id, updated_at', :conditions => ["state = 'released'"], :order => 'updated_at DESC', :limit => limit)
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
  
  def title
    self.name
  end
  

  protected

  def correct_bitrate
    Mp3Info.open(audio.to_file.path) do |mp3info|
      errors.add(:audio, ' data must have a bitrate of 128 kbps') unless mp3info.bitrate == 128
    end if audio?
  rescue Mp3InfoError => e
    errors.add(:audio, "unable to process file (#{e.message})")
  end
  
  def set_mp3_tags
    Mp3Info.open(audio.path) do |mp3|
      mp3.tag.title = name
      mp3.tag.artist = "[www.computer-beatz.net] " + project.name
      mp3.tag.album = ''
      mp3.tag.year = Time.now.year
      mp3.tag.comments = "This track is released on www.computer-beatz.net"
    end if audio?
  rescue Mp3InfoError => e
    errors.add(:audio, "unable to process file (#{e.message})")
  end

  
end
