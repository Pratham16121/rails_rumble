class RevealAnswer
  def self.call(quiz_session:)
    return { error: "Quiz not in progress" } unless quiz_session.in_progress?
    return { error: "Answer already revealed" } if quiz_session.answer_revealed?

    quiz_session.update!(answer_revealed: true)

    { success: true }
  end
end
