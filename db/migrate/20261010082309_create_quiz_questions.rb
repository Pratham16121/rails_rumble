class CreateQuizQuestions < ActiveRecord::Migration[8.0]
  def change
    create_table :quiz_questions do |t|
      t.references :quiz_session, null: false, foreign_key: true
      t.text :question_text, null: false
      t.integer :position, null: false
      t.integer :points, null: false, default: 0
      t.integer :time_limit_seconds, null: false

      t.timestamps
    end
    add_index :quiz_questions, [ :quiz_session_id, :position ]
  end
end
