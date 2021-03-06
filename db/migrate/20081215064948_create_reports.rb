class CreateReports < ActiveRecord::Migration
  def self.up
    create_table :reports do |t|
      t.integer :user_id
      t.integer :reportable_id
      t.string :reportable_type
      t.string :status
      t.timestamps
    end
  end

  def self.down
    drop_table :reports
  end
end
