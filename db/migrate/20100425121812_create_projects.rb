class CreateProjects < ActiveRecord::Migration
  def self.up
    create_table :projects do |t|
      t.string :name, :null => false
      t.text :description
      
      t.column :logo_file_name,           :string # Original filename
      t.column :logo_content_type,        :string # Mime type
      t.column :logo_file_size,           :integer # File size in bytes
      t.column :license,                  :string, :limit => 10, :null => false
      t.integer :comments_count, :null => false, :default => 0

      t.timestamps
    end
    add_index :projects, :name, :unique => true
  end

  def self.down
    drop_table :projects
  end
end
