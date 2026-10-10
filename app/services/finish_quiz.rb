class FinishQuiz
  def self.call(quiz_session:)
    quiz_session.update!(
      status: :finished,
      finished_at: Time.current,
      current_question: nil
    )
    
    { success: true }
  end
end
