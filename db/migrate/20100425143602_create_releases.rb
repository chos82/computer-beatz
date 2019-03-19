class CreateReleases < ActiveRecord::Migration
  def self.up
    create_table :releases do |t|
      t.string :name, :null => false
      t.text :description
      t.integer :project_id, :null => false
      t.string :state, :null => false
      t.integer :favourites_count, :null => false, :default => 0
      t.integer :comments_count, :null => false, :default => 0
     
      t.column :cover_file_name,           :string # Original filename
      t.column :cover_content_type,        :string # Mime type
      t.column :cover_file_size,           :integer # File size in bytes
     
      t.column :audio_file_name,           :string # Original filename
      t.column :audio_content_type,        :string # Mime type
      t.column :audio_file_size,           :integer # File size in bytes
     
      t.timestamps
    end
    add_index :releases, :favourites_count, :unique => false
    add_index :releases, :comments_count, :unique => false
    add_index :releases, :project_id, :unique => false
  end

  def self.down
    drop_table :releases
  end
end
