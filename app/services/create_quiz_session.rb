class CreateQuizSession
  # Join codes skip lookalike characters (0/O, 1/I/L) so they're easy to read off a screen.
  JOIN_CODE_ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789".chars.freeze
  JOIN_CODE_LENGTH = 6

  def self.call(quiz_session:)
    host_token = SecretToken.generate

    quiz_session.join_code = generate_join_code
    quiz_session.host_token_digest = SecretToken.digest(host_token)
    quiz_session.status = :waiting

    if quiz_session.save
      { success: true, host_token: host_token }
    else
      { success: false }
    end
  end

  def self.generate_join_code
    loop do
      code = Array.new(JOIN_CODE_LENGTH) { JOIN_CODE_ALPHABET.sample(random: SecureRandom) }.join
      break code unless QuizSession.exists?(join_code: code)
    end
  end
end
