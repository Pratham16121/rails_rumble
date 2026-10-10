class JoinQuizSession
  def self.call(join_code:, nickname:)
    session = QuizSession.find_by(join_code: join_code.to_s.strip.upcase)
    return { error: "We couldn't find a quiz with that code" } unless session
    return { error: "That quiz has already started" } unless session.waiting?

    player_token = SecretToken.generate
    participant = session.quiz_participants.build(
      nickname: nickname,
      session_token_digest: SecretToken.digest(player_token),
      status: :waiting,
      joined_at: Time.current
    )
    return { error: participant.errors.full_messages.to_sentence } unless participant.save

    { quiz_participant: participant, player_token: player_token, quiz_session: session }
  end
end
