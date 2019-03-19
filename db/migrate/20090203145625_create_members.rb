class CreateMembers < ActiveRecord::Migration
  def self.up
    create_table :members do |t|
      t.integer :group_id, :null => false
      t.integer :user_id, :null => false
      t.boolean :news_notification, :default => true
      t.string :status, :default => 'active'
      t.integer :no_messages, :default => 0
      t.boolean :was_activated, :default => true
    
      t.timestamps
    end
    
    add_index :members, [:user_id, :group_id], :unique => true
    add_index :members, :user_id, :unique => false
    add_index :members, :group_id, :unique => false

  end

  def self.down
    drop_table :members
  end
end
