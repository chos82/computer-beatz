class AlbumsTracks < ActiveRecord::Migration
 
  def self.up
    create_table :albums_tracks, :id => false do |t|
      t.integer :album_id
      t.integer :track_id
    end
    add_index :albums_tracks, [:album_id, :track_id], :unique => true
    add_index :albums_tracks, :album_id, :unique => false
  end

  def self.down
    drop_table :albums_tracks
  end
end
