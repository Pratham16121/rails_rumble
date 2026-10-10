class AdvanceQuestion
  def self.call(quiz_session:)
    return { error: "Quiz not in progress" } unless quiz_session.in_progress?
    return { error: "No active question" } unless quiz_session.current_question

    if (next_question = quiz_session.next_question)
      quiz_session.update!(current_question: next_question, question_started_at: Time.current, answer_revealed: false)
    else
      FinishQuiz.call(quiz_session: quiz_session)
    end

    { success: true }
  end
end
