# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20131019094058) do

  create_table "albums_tracks", :id => false, :force => true do |t|
    t.integer "album_id"
    t.integer "track_id"
  end

  add_index "albums_tracks", ["album_id", "track_id"], :name => "index_albums_tracks_on_album_id_and_track_id", :unique => true
  add_index "albums_tracks", ["album_id"], :name => "index_albums_tracks_on_album_id"

  create_table "artists_labels", :id => false, :force => true do |t|
    t.integer "artist_id"
    t.integer "label_id"
  end

  add_index "artists_labels", ["artist_id", "label_id"], :name => "index_artists_labels_on_artist_id_and_label_id", :unique => true
  add_index "artists_labels", ["label_id"], :name => "index_artists_labels_on_label_id"

  create_table "comments", :force => true do |t|
    t.text     "text",                           :null => false
    t.integer  "user_id"
    t.integer  "commentable_id",                 :null => false
    t.string   "commentable_type", :limit => 20, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "comments", ["commentable_id"], :name => "index_comments_on_commentable_id"
  add_index "comments", ["user_id"], :name => "index_comments_on_user_id"

  create_table "emails", :force => true do |t|
    t.string   "from"
    t.string   "to"
    t.integer  "last_send_attempt", :default => 0
    t.text     "mail"
    t.datetime "created_on"
  end

  create_table "favourites", :force => true do |t|
    t.integer  "favourizable_id",                 :null => false
    t.string   "favourizable_type", :limit => 20, :null => false
    t.integer  "user_id",                         :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "favourites", ["favourizable_id", "user_id"], :name => "index_favourites_on_favourizable_id_and_user_id", :unique => true
  add_index "favourites", ["favourizable_id"], :name => "index_favourites_on_favourizable_id"
  add_index "favourites", ["user_id"], :name => "index_favourites_on_user_id"

  create_table "friendships", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.integer  "friend_id",  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "friendships", ["friend_id"], :name => "index_friendships_on_friend_id"
  add_index "friendships", ["user_id"], :name => "index_friendships_on_user_id"

  create_table "group_invitations", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "groups", :force => true do |t|
    t.string   "title"
    t.text     "description"
    t.integer  "admin"
    t.boolean  "locked",            :default => false
    t.boolean  "public",            :default => true
    t.boolean  "join_requests",     :default => true
    t.string   "logo_file_name"
    t.string   "logo_content_type"
    t.integer  "logo_file_size"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "guestbook_entries", :force => true do |t|
    t.integer  "sender",     :null => false
    t.integer  "reciever",   :null => false
    t.text     "text"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "guestbook_entries", ["reciever"], :name => "index_guestbook_entries_on_reciever"
  add_index "guestbook_entries", ["sender"], :name => "index_guestbook_entries_on_sender"

  create_table "invitations", :force => true do |t|
    t.integer  "sender",     :null => false
    t.integer  "reciever",   :null => false
    t.integer  "group_id",   :null => false
    t.string   "type",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "invitations", ["reciever"], :name => "index_invitations_on_reciever"
  add_index "invitations", ["sender"], :name => "index_invitations_on_sender"

  create_table "members", :force => true do |t|
    t.integer  "group_id",                                :null => false
    t.integer  "user_id",                                 :null => false
    t.boolean  "news_notification", :default => true
    t.string   "status",            :default => "active"
    t.integer  "no_messages",       :default => 0
    t.boolean  "was_activated",     :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "members", ["group_id"], :name => "index_members_on_group_id"
  add_index "members", ["user_id", "group_id"], :name => "index_members_on_user_id_and_group_id", :unique => true
  add_index "members", ["user_id"], :name => "index_members_on_user_id"

  create_table "messages", :force => true do |t|
    t.string   "type"
    t.text     "text"
    t.string   "subject"
    t.integer  "sender",                        :null => false
    t.integer  "reciever",                      :null => false
    t.boolean  "read",       :default => false
    t.boolean  "replied",    :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "messages", ["reciever"], :name => "index_messages_on_reciever"
  add_index "messages", ["sender"], :name => "index_messages_on_sender"

  create_table "music", :force => true do |t|
    t.string   "type"
    t.string   "name"
    t.integer  "comments_count",   :default => 0
    t.integer  "favourites_count", :default => 0
    t.integer  "taggings_count",   :default => 0
    t.integer  "created_by",       :default => 1
    t.string   "license",          :default => "unknown"
    t.string   "www"
    t.date     "release_date"
    t.integer  "artist_id"
    t.integer  "label_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "music", ["comments_count"], :name => "index_music_on_comments_count"
  add_index "music", ["favourites_count"], :name => "index_music_on_favourites_count"
  add_index "music", ["taggings_count"], :name => "index_music_on_taggings_count"

  create_table "news", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "news_messages", :force => true do |t|
    t.integer  "sender",                           :null => false
    t.integer  "thread_id",                        :null => false
    t.string   "subject",                          :null => false
    t.text     "text"
    t.boolean  "admin_message", :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "news_messages", ["sender"], :name => "index_news_messages_on_sender"
  add_index "news_messages", ["thread_id"], :name => "index_news_messages_on_thread_id"

  create_table "newsletters", :force => true do |t|
    t.string   "subject"
    t.text     "text"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "page_impressions", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "permissions", :force => true do |t|
    t.integer  "role_id",    :null => false
    t.integer  "user_id",    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "project_memberships", :force => true do |t|
    t.integer  "user_id",                                              :null => false
    t.integer  "project_id",                                           :null => false
    t.string   "status",               :limit => 20
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "comment_notification",               :default => true
  end

  add_index "project_memberships", ["project_id", "user_id"], :name => "index_project_memberships_on_project_id_and_user_id", :unique => true
  add_index "project_memberships", ["project_id"], :name => "index_project_memberships_on_project_id"

  create_table "projects", :force => true do |t|
    t.string   "name",                                           :null => false
    t.text     "description"
    t.string   "logo_file_name"
    t.string   "logo_content_type"
    t.integer  "logo_file_size"
    t.string   "license",           :limit => 10,                :null => false
    t.integer  "comments_count",                  :default => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "projects", ["name"], :name => "index_projects_on_name", :unique => true

  create_table "ratings", :force => true do |t|
    t.integer  "rating",                      :default => 0
    t.datetime "created_at",                                  :null => false
    t.string   "rateable_type", :limit => 15, :default => "", :null => false
    t.integer  "rateable_id",                 :default => 0,  :null => false
    t.integer  "user_id",                     :default => 0,  :null => false
  end

  add_index "ratings", ["user_id"], :name => "fk_ratings_user"

  create_table "releases", :force => true do |t|
    t.string   "name",                              :null => false
    t.text     "description"
    t.integer  "project_id",                        :null => false
    t.string   "state",                             :null => false
    t.integer  "favourites_count",   :default => 0, :null => false
    t.integer  "comments_count",     :default => 0, :null => false
    t.string   "cover_file_name"
    t.string   "cover_content_type"
    t.integer  "cover_file_size"
    t.string   "audio_file_name"
    t.string   "audio_content_type"
    t.integer  "audio_file_size"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "releases", ["comments_count"], :name => "index_releases_on_comments_count"
  add_index "releases", ["favourites_count"], :name => "index_releases_on_favourites_count"
  add_index "releases", ["project_id"], :name => "index_releases_on_project_id"

  create_table "reports", :force => true do |t|
    t.integer  "user_id"
    t.integer  "reportable_id"
    t.string   "reportable_type"
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles", :force => true do |t|
    t.string "rolename"
  end

  create_table "slugs", :force => true do |t|
    t.string   "name"
    t.integer  "sluggable_id"
    t.integer  "sequence",                     :default => 1, :null => false
    t.string   "sluggable_type", :limit => 40
    t.string   "scope"
    t.datetime "created_at"
  end

  add_index "slugs", ["name", "sluggable_type", "sequence", "scope"], :name => "index_slugs_on_n_s_s_and_s", :unique => true
  add_index "slugs", ["sluggable_id"], :name => "index_slugs_on_sluggable_id"

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "taggable_type"
    t.string   "context"
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type", "context"], :name => "index_taggings_on_taggable_id_and_taggable_type_and_context"

  create_table "tags", :force => true do |t|
    t.string "name"
  end

  create_table "topics", :force => true do |t|
    t.string   "title"
    t.integer  "group_id",            :null => false
    t.integer  "user_id"
    t.integer  "news_messages_count"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "topics", ["group_id"], :name => "index_topics_on_group_id"

  create_table "track_listings", :id => false, :force => true do |t|
    t.integer "mix_id",       :null => false
    t.integer "track_id",     :null => false
    t.integer "start_time"
    t.integer "track_number", :null => false
  end

  add_index "track_listings", ["mix_id", "track_id"], :name => "index_track_listings_on_mix_id_and_track_id", :unique => true
  add_index "track_listings", ["mix_id"], :name => "index_track_listings_on_mix_id"
  add_index "track_listings", ["track_id"], :name => "index_track_listings_on_track_id"

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "email"
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.string   "activation_code",           :limit => 40
    t.datetime "activated_at"
    t.boolean  "enabled",                                 :default => true
    t.string   "gender"
    t.date     "birthday"
    t.datetime "last_login"
    t.string   "country"
    t.string   "city"
    t.string   "zip"
    t.string   "time_zone"
    t.string   "www"
    t.text     "motto"
    t.integer  "no_items",                                :default => 0
    t.boolean  "message_notify",                          :default => true
    t.boolean  "newsletter",                              :default => true
    t.string   "avatar_file_name"
    t.string   "avatar_content_type"
    t.integer  "avatar_file_size"
    t.boolean  "invitation_notify",                       :default => true
    t.boolean  "guestbook_notify",                        :default => true
    t.string   "motto_privacy",             :limit => 15, :default => "friends"
    t.string   "guestbook_privacy",         :limit => 15, :default => "friends"
    t.string   "groups_privacy",            :limit => 15, :default => "friends"
    t.string   "tagged_privacy",            :limit => 15, :default => "friends"
    t.string   "friendships_privacy",       :limit => 15, :default => "friends"
    t.string   "favourites_privacy",        :limit => 15, :default => "friends"
    t.string   "password_reset_code",       :limit => 40
  end

  add_index "users", ["no_items"], :name => "index_users_on_no_items"

  create_table "videos", :force => true do |t|
    t.integer "track_id",   :null => false
    t.string  "youtube_id", :null => false
  end

  add_index "videos", ["track_id"], :name => "index_videos_on_track_id", :unique => true

end
