class JoinQuizSession
  def self.call(join_code:, nickname:)
    session = QuizSession.find_by(join_code: join_code.upcase)
    return { error: 'Invalid join code' } unless session
    return { error: 'Quiz already started' } unless session.waiting?

    player_token = SecureRandom.urlsafe_base64
    player_token_digest = Digest::SHA256.hexdigest(player_token)

    participant = session.quiz_participants.create!(
      nickname: nickname,
      session_token_digest: player_token_digest,
      status: :waiting,
      joined_at: Time.current
    )

    { quiz_participant: participant, player_token: player_token, quiz_session: session }
  end
end
