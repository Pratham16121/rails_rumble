class AddQuestionStartedAtToQuizSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :quiz_sessions, :question_started_at, :datetime
  end
end
