class CreatePageImpressions < ActiveRecord::Migration
  def self.up
    create_table :page_impressions do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :page_impressions
  end
end
