class CreateTopics < ActiveRecord::Migration
  def self.up
    create_table :topics do |t|
      t.string :title
      t.integer :group_id, :null => false
      t.integer :user_id
      t.integer :news_messages_count

      t.timestamps
    end
    add_index :topics, :group_id, :unique => false
  end

  def self.down
    drop_table :topics
  end
end
