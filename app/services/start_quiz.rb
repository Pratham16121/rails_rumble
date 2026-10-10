class StartQuiz
  def self.call(quiz_session:)
    return { error: "Quiz is not waiting" } unless quiz_session.waiting?

    first_question = quiz_session.quiz_questions.first
    return { error: "Cannot start quiz without questions" } unless first_question

    QuizSession.transaction do
      quiz_session.update!(
        status: :in_progress,
        started_at: Time.current,
        current_question: first_question,
        question_started_at: Time.current,
        answer_revealed: false
      )
      quiz_session.quiz_participants.update_all(status: :playing)
    end

    { success: true, quiz_session: quiz_session }
  end
end
