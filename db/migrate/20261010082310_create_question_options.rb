class CreateQuestionOptions < ActiveRecord::Migration[8.0]
  def change
    create_table :question_options do |t|
      t.references :quiz_question, null: false, foreign_key: true
      t.string :option_text, null: false
      t.integer :position, null: false
      t.boolean :correct, null: false, default: false

      t.timestamps
    end
    add_index :question_options, [:quiz_question_id, :position]
  end
end
