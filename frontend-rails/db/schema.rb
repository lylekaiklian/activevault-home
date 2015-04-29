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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150429065613) do

  create_table "scenarios", force: :cascade do |t|
    t.string   "batch",             limit: 255
    t.integer  "sequence_no",       limit: 4
    t.integer  "ref_no",            limit: 4
    t.datetime "test_date"
    t.text     "description",       limit: 65535
    t.string   "keyword",           limit: 255
    t.string   "a_number",          limit: 255
    t.string   "b_number",          limit: 255
    t.text     "expected_result",   limit: 65535
    t.datetime "time_sent"
    t.datetime "time_received"
    t.integer  "beginning_balance", limit: 4
    t.integer  "ending_balance",    limit: 4
    t.integer  "amount_charged",    limit: 4
    t.text     "actual_result",     limit: 65535
    t.boolean  "pass_or_fail",      limit: 1
    t.text     "remarks",           limit: 65535
    t.string   "ussd_command",      limit: 255
    t.string   "ussd_number",       limit: 255
    t.string   "type",              limit: 255
  end

end
