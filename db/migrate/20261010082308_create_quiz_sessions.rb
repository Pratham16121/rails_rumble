class CreateQuizSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :quiz_sessions do |t|
      t.string :title, null: false
      t.string :join_code, null: false
      t.integer :status, null: false, default: 0
      t.string :host_token_digest, null: false
      t.datetime :started_at
      t.datetime :finished_at
      t.integer :current_question_id

      t.timestamps
    end
    add_index :quiz_sessions, :join_code, unique: true
  end
end
