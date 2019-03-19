class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table "users", :force => true do |t|
      t.column :login,                     :string
      t.column :email,                     :string
      t.column :crypted_password,          :string, :limit => 40
      t.column :salt,                      :string, :limit => 40
      t.column :created_at,                :datetime
      t.column :updated_at,                :datetime
      t.column :remember_token,            :string
      t.column :remember_token_expires_at, :datetime
      t.column :activation_code, :string, :limit => 40
      t.column :activated_at, :datetime
      t.column :enabled, :boolean, :default => true
      t.column :gender,                    :string
      t.column :birthday,                  :date
      t.column :last_login,                :datetime
      t.column :gender,                    :string
      t.column :country,                   :string
      t.column :city,                      :string
      t.column :zip,                       :string
      t.column :time_zone,                 :string
      t.column :www,                       :string
      t.column :motto,                     :text, :limit => 3000
      t.column :no_items,                  :integer, :default => 0
      t.column :message_notify,           :boolean, :default => true
      t.column :newsletter,                 :boolean, :default => true
      t.column :avatar_file_name,           :string # Original filename
      t.column :avatar_content_type,        :string # Mime type
      t.column :avatar_file_size,           :integer # File size in bytes
      t.column :invitation_notify,          :boolean, :default => true
      t.column :guestbook_notify,          :boolean, :default => true
      t.column :motto_privacy,              :string, :limit => 15, :default => 'friends'
      t.column :guestbook_privacy,              :string, :limit => 15, :default => 'friends'
      t.column :groups_privacy,              :string, :limit => 15, :default => 'friends'
      t.column :tagged_privacy,              :string, :limit => 15, :default => 'friends'
      t.column :friendships_privacy,              :string, :limit => 15, :default => 'friends'
      t.column :favourites_privacy,              :string, :limit => 15, :default => 'friends'
      
    end
    add_index :users, :no_items, :unique => false
  end

  def self.down
    drop_table "users"
  end
end
