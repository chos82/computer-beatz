class CreateComments < ActiveRecord::Migration
  def self.up
    create_table :comments do |t|
      t.text :text,        :null => false
      t.integer :user_id
      t.integer :commentable_id, :null => false
      t.string :commentable_type, :null => false, :limit => 20

      t.timestamps
    end
    add_index :comments, [:commentable_id], :unique => false
    add_index :comments, :user_id, :unique => false
  end

  def self.down
    drop_table :comments
  end
end
