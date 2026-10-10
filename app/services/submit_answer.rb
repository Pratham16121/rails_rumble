class SubmitAnswer
  def self.call(quiz_participant:, player_token:, question_option_id:)
    return { error: 'Unauthorized' } unless Digest::SHA256.hexdigest(player_token) == quiz_participant.session_token_digest
    
    session = quiz_participant.quiz_session
    return { error: 'Quiz not in progress' } unless session.in_progress?
    
    question = session.current_question
    return { error: 'No active question' } unless question
    
    option = question.question_options.find_by(id: question_option_id)
    return { error: 'Invalid option' } unless option

    result = nil
    PlayerAnswer.transaction do
      if PlayerAnswer.exists?(quiz_participant_id: quiz_participant.id, quiz_question_id: question.id)
        result = { error: 'Already answered' }
        raise ActiveRecord::Rollback
      end

      answer = PlayerAnswer.create!(
        quiz_participant: quiz_participant,
        quiz_question: question,
        question_option: option,
        correct: option.correct,
        points_awarded: option.correct ? question.points : 0,
        answered_at: Time.current
      )

      if option.correct
        quiz_participant.increment!(:total_score, question.points)
      end
      
      result = { success: true }
    end

    result
  end
end
