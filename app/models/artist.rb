class Artist < Music
  has_and_belongs_to_many :labels
  has_many :tracks
  has_many :albums
  
end
