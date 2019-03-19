class TrackListing < ActiveRecord::Base
  
  belongs_to :track
  belongs_to :mix
  
end
