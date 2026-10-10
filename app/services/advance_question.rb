class AdvanceQuestion
  def self.call(quiz_session:, host_token:)
    return { error: 'Unauthorized' } unless Digest::SHA256.hexdigest(host_token) == quiz_session.host_token_digest
    return { error: 'Quiz not in progress' } unless quiz_session.in_progress?

    current_question = quiz_session.current_question
    return { error: 'No active question' } unless current_question

    next_question = quiz_session.quiz_questions.where('position > ?', current_question.position).order(:position).first

    if next_question
      quiz_session.update!(current_question: next_question, answer_revealed: false)
    else
      FinishQuiz.call(quiz_session: quiz_session)
    end

    { success: true }
  end
end
