class AddAnswerRevealedToQuizSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :quiz_sessions, :answer_revealed, :boolean, default: false, null: false
  end
end
