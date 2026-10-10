class QuizParticipant < ApplicationRecord
  belongs_to :quiz_session
  has_many :player_answers, dependent: :destroy

  enum :status, { waiting: 0, playing: 1 }

  normalizes :nickname, with: ->(nickname) { nickname.squish }

  validates :nickname, presence: true, length: { maximum: 30 },
    uniqueness: { scope: :quiz_session_id, case_sensitive: false, message: "is already taken in this quiz" }
  validates :session_token_digest, presence: true
  validates :joined_at, presence: true

  def valid_token?(token)
    SecretToken.matches?(token, session_token_digest)
  end

  # Correct answers in a row on the questions just before this one
  def streak_before(question)
    earlier = quiz_session.quiz_questions.where("position < ?", question.position).reorder(position: :desc).pluck(:id)
    correct = player_answers.where(correct: true, quiz_question_id: earlier).pluck(:quiz_question_id)
    earlier.take_while { |id| correct.include?(id) }.size
  end

  def current_answer
    question = quiz_session.current_question
    player_answers.find_by(quiz_question: question) if question
  end

  # Points for the current question stay hidden until the host reveals the answer,
  # so a jump in score can't give away whether the player was right.
  def visible_score
    return total_score if quiz_session.answer_revealed?

    total_score - (current_answer&.points_awarded || 0)
  end

  def broadcast_game
    broadcast_replace_to self, target: "player_game",
      partial: "quiz_participants/game", locals: { participant: self }
  end
end
