class Album < Music
  belongs_to :artist
  belongs_to :label
  has_and_belongs_to_many :tracks
  
end