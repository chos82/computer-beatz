class CreateProjectMemberships < ActiveRecord::Migration
  def self.up
    create_table :project_memberships do |t|
      t.integer :user_id, :null => false
      t.integer :project_id, :null => false
      t.string :status, :limit => 20

      t.timestamps
    end
    add_index :project_memberships, [:project_id, :user_id], :unique => true
    add_index :project_memberships, :project_id, :unique => false
  end

  def self.down
    drop_table :project_memberships
  end
end
