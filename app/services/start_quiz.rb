class StartQuiz
  def self.call(quiz_session:, host_token:)
    return { error: 'Unauthorized' } unless Digest::SHA256.hexdigest(host_token) == quiz_session.host_token_digest
    return { error: 'Quiz is not waiting' } unless quiz_session.waiting?

    if quiz_session.quiz_questions.empty?
      return { error: 'Cannot start quiz without questions' }
    end

    first_question = quiz_session.quiz_questions.order(:position).first

    QuizSession.transaction do
      quiz_session.update!(
        status: :in_progress,
        started_at: Time.current,
        current_question: first_question
      )
      quiz_session.quiz_participants.update_all(status: :playing)
    end
    
    { success: true, quiz_session: quiz_session }
  end
end
