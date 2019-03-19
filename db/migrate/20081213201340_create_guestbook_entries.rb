class CreateGuestbookEntries < ActiveRecord::Migration
  def self.up
    create_table :guestbook_entries do |t|
      t.integer :sender, :null => false
      t.integer :reciever, :null => false
      t.text :text

      t.timestamps
    end
    add_index :guestbook_entries, :reciever, :unique => false
    add_index :guestbook_entries, :sender, :unique => false
  end

  def self.down
    drop_table :guestbook_entries
  end
end
