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

ActiveRecord::Schema[8.0].define(version: 2026_10_10_123101) do
  create_table "player_answers", force: :cascade do |t|
    t.integer "quiz_participant_id", null: false
    t.integer "quiz_question_id", null: false
    t.integer "question_option_id"
    t.boolean "correct", default: false, null: false
    t.integer "points_awarded", default: 0, null: false
    t.datetime "answered_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "response_time_ms"
    t.integer "streak", default: 0, null: false
    t.index ["question_option_id"], name: "index_player_answers_on_question_option_id"
    t.index ["quiz_participant_id", "quiz_question_id"], name: "idx_on_quiz_participant_id_quiz_question_id_7d097045a7", unique: true
    t.index ["quiz_participant_id"], name: "index_player_answers_on_quiz_participant_id"
    t.index ["quiz_question_id"], name: "index_player_answers_on_quiz_question_id"
  end

  create_table "question_options", force: :cascade do |t|
    t.integer "quiz_question_id", null: false
    t.string "option_text", null: false
    t.integer "position", null: false
    t.boolean "correct", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["quiz_question_id", "position"], name: "index_question_options_on_quiz_question_id_and_position"
    t.index ["quiz_question_id"], name: "index_question_options_on_quiz_question_id"
  end

  create_table "quiz_participants", force: :cascade do |t|
    t.integer "quiz_session_id", null: false
    t.string "nickname", limit: 30, null: false
    t.string "session_token_digest", null: false
    t.integer "status", default: 0, null: false
    t.integer "total_score", default: 0, null: false
    t.datetime "joined_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["quiz_session_id", "joined_at"], name: "index_quiz_participants_on_quiz_session_id_and_joined_at"
    t.index ["quiz_session_id"], name: "index_quiz_participants_on_quiz_session_id"
  end

  create_table "quiz_questions", force: :cascade do |t|
    t.integer "quiz_session_id", null: false
    t.text "question_text", null: false
    t.integer "position", null: false
    t.integer "points", default: 0, null: false
    t.integer "time_limit_seconds", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["quiz_session_id", "position"], name: "index_quiz_questions_on_quiz_session_id_and_position"
    t.index ["quiz_session_id"], name: "index_quiz_questions_on_quiz_session_id"
  end

  create_table "quiz_sessions", force: :cascade do |t|
    t.string "title", null: false
    t.string "join_code", null: false
    t.integer "status", default: 0, null: false
    t.string "host_token_digest", null: false
    t.datetime "started_at"
    t.datetime "finished_at"
    t.integer "current_question_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "answer_revealed", default: false, null: false
    t.datetime "question_started_at"
    t.index ["join_code"], name: "index_quiz_sessions_on_join_code", unique: true
  end

  add_foreign_key "player_answers", "question_options"
  add_foreign_key "player_answers", "quiz_participants"
  add_foreign_key "player_answers", "quiz_questions"
  add_foreign_key "question_options", "quiz_questions"
  add_foreign_key "quiz_participants", "quiz_sessions"
  add_foreign_key "quiz_questions", "quiz_sessions"
  add_foreign_key "quiz_sessions", "quiz_questions", column: "current_question_id"
end
