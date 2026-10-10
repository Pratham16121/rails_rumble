class CreateQuizSession
  def self.call(quiz_session:)
    host_token = SecureRandom.urlsafe_base64
    
    quiz_session.join_code = generate_join_code
    quiz_session.host_token_digest = Digest::SHA256.hexdigest(host_token)
    quiz_session.status = :waiting

    if quiz_session.save
      { success: true, host_token: host_token }
    else
      { success: false }
    end
  end

  def self.generate_join_code
    loop do
      code = SecureRandom.alphanumeric(6).upcase
      break code unless QuizSession.exists?(join_code: code)
    end
  end
end
