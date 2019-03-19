class CreateFavourites < ActiveRecord::Migration
  def self.up
    create_table :favourites do |t|
        t.integer :favourizable_id, :null => false
        t.string :favourizable_type, :null => false, :limit => 20
        t.integer :user_id,  :null => false
        
        t.timestamps
      end
      add_index :favourites, [:favourizable_id, :user_id], :unique => true
      add_index :favourites, :user_id, :unique => false
      add_index :favourites, :favourizable_id, :unique => false
  end

  def self.down
    drop_table :favourites
  end
end
