class CreateMessages < ActiveRecord::Migration
  def self.up
    create_table :messages do |t|
      t.string :type #Inbox / Outbox
      t.text :text
      t.string :subject
      t.integer :sender, :null => false
      t.integer :reciever, :null => false
      t.boolean :read, :default => false
      t.boolean :replied, :default => false

      t.timestamps
    end
    add_index :messages, :sender, :unique => false
    add_index :messages, :reciever, :unique => false
  end

  def self.down
    drop_table :messages
  end
end
