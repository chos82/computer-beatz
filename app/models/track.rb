class Track < Music
  belongs_to :artist
  belongs_to :label
  has_and_belongs_to_many :albums
  has_one :video
  has_many :track_listings, :dependent => :destroy
  has_many :mixes, :through => :track_listings
  
end