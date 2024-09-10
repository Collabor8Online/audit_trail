# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2024_09_09_212715) do
  create_table "audit_trail_events", force: :cascade do |t|
    t.string "user_type"
    t.integer "user_id"
    t.integer "context_id"
    t.string "partition", default: "event", null: false
    t.string "name", default: "event", null: false
    t.integer "status", default: 0, null: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["context_id"], name: "index_audit_trail_events_on_context_id"
    t.index ["id", "partition"], name: "index_audit_trail_events_on_id_and_partition", unique: true
    t.index ["name"], name: "index_audit_trail_events_on_name"
    t.index ["user_type", "user_id"], name: "index_audit_trail_events_on_user"
  end

  create_table "audit_trail_linked_models", force: :cascade do |t|
    t.string "partition", default: "event", null: false
    t.integer "event_id", null: false
    t.string "model_type"
    t.integer "model_id"
    t.string "name", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_audit_trail_linked_models_on_event_id"
    t.index ["id", "partition"], name: "index_audit_trail_linked_models_on_id_and_partition", unique: true
    t.index ["model_type", "model_id"], name: "index_audit_trail_linked_models_on_model"
  end

  create_table "posts", force: :cascade do |t|
    t.integer "user_id"
    t.string "title"
    t.text "contents"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end
end
