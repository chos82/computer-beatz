class CreateGroups < ActiveRecord::Migration
  def self.up
    create_table :groups do |t|
      t.string :title
      t.text :description, :limit => 3000
      t.integer :admin
      t.boolean :locked, :default => false
      t.boolean :public, :default => true
      t.boolean :join_requests, :default => true
      
      t.column :logo_file_name,           :string # Original filename
      t.column :logo_content_type,        :string # Mime type
      t.column :logo_file_size,           :integer # File size in bytes
      
      t.timestamps
    end
  end

  def self.down
    drop_table :groups
  end
end
