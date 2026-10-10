class SubmitAnswer
  def self.call(quiz_participant:, question_option_id:)
    session = quiz_participant.quiz_session
    question = session.current_question
    return { error: "Answers are closed for this question" } unless question && session.accepting_answers?

    option = question.question_options.find_by(id: question_option_id)
    return { error: "Invalid option" } unless option

    answered_at = Time.current
    response_time = answered_at - session.question_started_at
    streak = option.correct ? quiz_participant.streak_before(question) + 1 : 0
    points = option.correct ? question.points_for(response_time) + PlayerAnswer.streak_bonus(streak) : 0

    PlayerAnswer.transaction do
      quiz_participant.player_answers.create!(
        quiz_question: question,
        question_option: option,
        correct: option.correct,
        points_awarded: points,
        answered_at: answered_at,
        response_time_ms: [ (response_time * 1000).round, 0 ].max,
        streak: streak
      )
      quiz_participant.increment!(:total_score, points) if points.positive?
    end

    { success: true }
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    { error: "You've already answered this question" }
  end
end
