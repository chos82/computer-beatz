class Mix < Music
  belongs_to :artist
  has_many :track_listings, :dependent => :destroy
  has_many :tracks, :through => :track_listings
  
  def highest_track_numer
    highest_listing = 0
    track_listings.each{|tl|
      highest_listing = highest_listing > tl.track_number ? highest_listing : tl.track_number
    }
    highest_listing
  end
  
end