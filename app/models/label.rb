class Label < Music
  has_and_belongs_to_many :artists
  has_many :tracks
  has_many :albums
  
  validates_inclusion_of :license, :in => %w{ commercial unknown free }
  
end
