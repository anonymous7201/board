# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110401205825) do

  create_table "pictures", :force => true do |t|
    t.string   "format"
    t.string   "name"
    t.integer  "size"
    t.integer  "post_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "origin"
    t.string   "hash"
  end

  add_index "pictures", ["hash"], :name => "index_pictures_on_hash"
  add_index "pictures", ["name"], :name => "index_pictures_on_name"
  add_index "pictures", ["origin"], :name => "index_pictures_on_origin"
  add_index "pictures", ["post_id"], :name => "index_pictures_on_post_id"
  add_index "pictures", ["size"], :name => "index_pictures_on_size"

  create_table "posts", :force => true do |t|
    t.string   "author"
    t.string   "ip"
    t.text     "message"
    t.integer  "number"
    t.integer  "replies"
    t.boolean  "sage"
    t.datetime "created_at"
    t.datetime "bump"
    t.integer  "parent_id"
    t.boolean  "deleted"
  end

  add_index "posts", ["ip"], :name => "index_posts_on_ip"
  add_index "posts", ["parent_id"], :name => "index_posts_on_parent_id"

end
