class FinishQuiz
  def self.call(quiz_session:)
    return { error: "Quiz not in progress" } unless quiz_session.in_progress?

    quiz_session.update!(
      status: :finished,
      finished_at: Time.current,
      current_question: nil,
      question_started_at: nil,
      answer_revealed: false
    )

    { success: true }
  end
end
