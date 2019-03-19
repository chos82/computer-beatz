class CreateInvitations < ActiveRecord::Migration
  def self.up
    create_table :invitations do |t|
      t.integer :sender, :null => false
      t.integer :reciever, :null => false
      t.integer :group_id, :null => false
      t.string  :type, :null => false

      t.timestamps
    end
    
    add_index :invitations, :sender, :unique => false
    add_index :invitations, :reciever, :unique => false
  end

  def self.down
    drop_table :invitations
  end
end
