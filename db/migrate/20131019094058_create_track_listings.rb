class CreateTrackListings < ActiveRecord::Migration
  def self.up
    create_table :track_listings, :id => false do |t|
      t.integer :mix_id, :null => false
      t.integer :track_id, :null => false
      t.integer :start_time
      t.integer :track_number, :null => false
    end
    add_index :track_listings, [:mix_id, :track_id], :unique => true
    add_index :track_listings, :mix_id, :unique => false
    add_index :track_listings, :track_id, :unique => false
  end

  def self.down
    drop_table :track_listings
  end
end
