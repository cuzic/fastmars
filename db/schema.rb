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

ActiveRecord::Schema.define(:version => 20091225084054) do

  create_table "bug_reports", :force => true do |t|
    t.integer  "member_id"
    t.integer  "item_id"
    t.string   "user_comment"
    t.string   "admin_comment"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "crawl_statuses", :force => true do |t|
    t.integer  "feed_id",          :default => 0, :null => false
    t.integer  "status",           :default => 1, :null => false
    t.integer  "error_count",      :default => 0, :null => false
    t.string   "error_message"
    t.integer  "http_status"
    t.string   "digest"
    t.integer  "update_frequency", :default => 0, :null => false
    t.datetime "crawled_on"
    t.datetime "created_on",                      :null => false
    t.datetime "updated_on",                      :null => false
  end

  add_index "crawl_statuses", ["status", "crawled_on"], :name => "index_crawl_statuses_on_status_and_crawled_on"

  create_table "favicons", :force => true do |t|
    t.integer "feed_id", :default => 0, :null => false
    t.binary  "image"
  end

  add_index "favicons", ["feed_id"], :name => "index_favicons_on_feed_id", :unique => true

  create_table "feeds", :force => true do |t|
    t.string   "feedlink",                         :null => false
    t.string   "link",                             :null => false
    t.text     "title",                            :null => false
    t.text     "description",                      :null => false
    t.integer  "subscribers_count", :default => 0, :null => false
    t.string   "image"
    t.string   "icon"
    t.datetime "modified_on"
    t.datetime "created_on",                       :null => false
    t.datetime "updated_on",                       :null => false
  end

  add_index "feeds", ["feedlink"], :name => "index_feeds_on_feedlink", :unique => true

  create_table "folders", :force => true do |t|
    t.integer  "member_id",  :default => 0, :null => false
    t.string   "name",                      :null => false
    t.datetime "created_on",                :null => false
    t.datetime "updated_on",                :null => false
  end

  add_index "folders", ["member_id", "name"], :name => "index_folders_on_member_id_and_name", :unique => true

  create_table "item_members", :force => true do |t|
    t.integer  "item_id"
    t.integer  "member_id"
    t.integer  "view_count", :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "item_members", ["item_id"], :name => "index_item_members_on_item_id"
  add_index "item_members", ["member_id"], :name => "index_item_members_on_member_id"

  create_table "items", :force => true do |t|
    t.integer  "feed_id",        :default => 0,  :null => false
    t.string   "link",           :default => "", :null => false
    t.text     "title",                          :null => false
    t.text     "body"
    t.string   "author"
    t.string   "category"
    t.string   "enclosure"
    t.string   "enclosure_type"
    t.string   "digest"
    t.integer  "version",        :default => 1,  :null => false
    t.datetime "stored_on"
    t.datetime "modified_on"
    t.datetime "created_on",                     :null => false
    t.datetime "updated_on",                     :null => false
    t.text     "html"
    t.integer  "bytesize"
  end

  add_index "items", ["feed_id", "link"], :name => "index_items_on_feed_id_and_link", :unique => true

  create_table "members", :force => true do |t|
    t.string   "username",                                       :null => false
    t.string   "email"
    t.string   "crypted_password"
    t.string   "salt"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.text     "config_dump"
    t.boolean  "public",                      :default => false, :null => false
    t.datetime "created_on",                                     :null => false
    t.datetime "updated_on",                                     :null => false
    t.string   "ident"
    t.string   "twitter_access_token"
    t.string   "twitter_access_token_secret"
  end

  add_index "members", ["username"], :name => "index_members_on_username", :unique => true

  create_table "pins", :force => true do |t|
    t.integer  "member_id",  :default => 0,  :null => false
    t.string   "link",       :default => "", :null => false
    t.string   "title"
    t.datetime "created_on",                 :null => false
    t.datetime "updated_on",                 :null => false
  end

  add_index "pins", ["member_id", "link"], :name => "index_pins_on_member_id_and_link", :unique => true

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "subscriptions", :force => true do |t|
    t.integer  "member_id",     :default => 0,     :null => false
    t.integer  "folder_id"
    t.integer  "feed_id",       :default => 0,     :null => false
    t.integer  "rate",          :default => 0,     :null => false
    t.boolean  "has_unread",    :default => false, :null => false
    t.boolean  "public",        :default => true,  :null => false
    t.boolean  "ignore_notify", :default => false, :null => false
    t.datetime "viewed_on"
    t.datetime "created_on",                       :null => false
    t.datetime "updated_on",                       :null => false
  end

  add_index "subscriptions", ["feed_id"], :name => "index_subscriptions_on_feed_id"
  add_index "subscriptions", ["folder_id"], :name => "index_subscriptions_on_folder_id"
  add_index "subscriptions", ["member_id", "feed_id"], :name => "index_subscriptions_on_member_id_and_feed_id", :unique => true

end
