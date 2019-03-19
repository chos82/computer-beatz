class CreateVideos < ActiveRecord::Migration
  def self.up
    create_table :videos do |t|
      t.integer :track_id, :null => false
      t.string :youtube_id, :null => false
    end
    
    add_index :videos, :track_id, :unique => true
  end

  def self.down
    drop_table :videos
  end
end
