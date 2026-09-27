ActiveRecord::Schema[8.1].define(version: 1) do
  create_table "discussions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
  end
end
