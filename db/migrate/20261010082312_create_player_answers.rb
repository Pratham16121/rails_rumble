class CreatePlayerAnswers < ActiveRecord::Migration[8.0]
  def change
    create_table :player_answers do |t|
      t.references :quiz_participant, null: false, foreign_key: true
      t.references :quiz_question, null: false, foreign_key: true
      t.references :question_option, foreign_key: true
      t.boolean :correct, null: false, default: false
      t.integer :points_awarded, null: false, default: 0
      t.datetime :answered_at

      t.timestamps
    end
    add_index :player_answers, [ :quiz_participant_id, :quiz_question_id ], unique: true
  end
end
