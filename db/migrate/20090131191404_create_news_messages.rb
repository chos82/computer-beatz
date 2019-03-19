class CreateNewsMessages < ActiveRecord::Migration
  def self.up
    create_table :news_messages do |t|
      t.integer :sender, :null => false
      t.integer :thread_id, :null => false
      t.string :subject, :null => false
      t.text :text, :limit => 3000
      t.boolean :admin_message, :default => false

      t.timestamps
    end
    add_index :news_messages, :sender, :unique => false
    add_index :news_messages, :thread_id, :unique => false
  end

  def self.down
    drop_table :news_messages
  end
end
