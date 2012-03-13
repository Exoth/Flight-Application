# encoding: UTF-8
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

ActiveRecord::Schema.define(:version => 20120312170409) do

  create_table "flights", :force => true do |t|
    t.decimal  "price",                  :precision => 10, :scale => 2, :null => false
    t.datetime "departure",                                             :null => false
    t.datetime "arrival",                                               :null => false
    t.string   "from",      :limit => 3,                                :null => false
    t.string   "to",        :limit => 3,                                :null => false
  end

  add_index "flights", ["departure"], :name => "index_flights_on_departure"
  add_index "flights", ["from", "to"], :name => "index_flights_on_from_and_to"
  add_index "flights", ["price"], :name => "index_flights_on_price"

end
