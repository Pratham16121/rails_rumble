class AddCurrentQuestionFkToQuizSessions < ActiveRecord::Migration[8.0]
  def change
    add_foreign_key :quiz_sessions, :quiz_questions, column: :current_question_id
  end
end
