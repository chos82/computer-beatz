class ArtistsLabels < ActiveRecord::Migration
  def self.up
    create_table :artists_labels, :id => false do |t|
      t.integer :artist_id
      t.integer :label_id
    end
    add_index :artists_labels, [:artist_id, :label_id], :unique => true
    add_index :artists_labels, :label_id, :unique => false
  end

  def self.down
    drop_table :artists_labels
  end
end
