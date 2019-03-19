class CreateMusic < ActiveRecord::Migration
  def self.up
    create_table :music do |t|
      #common attributes
      t.string :type
      t.string :name
      t.integer :comments_count, :default => 0
      t.integer :favourites_count, :default => 0
      t.integer :taggings_count, :default => 0
      t.integer :created_by, :default => 1
      
      t.string :license, :default => 'unknown'
      
      #attributes for label & artist
      t.string :www
      
      
      #attributes for track/album
      t.date :release_date
      t.integer :artist_id
      t.integer :label_id
      
      t.timestamps
    end
    add_index :music, :comments_count, :unique => false
    add_index :music, :favourites_count, :unique => false
    add_index :music, :taggings_count, :unique => false
  end

  def self.down
    drop_table :music
  end
end
