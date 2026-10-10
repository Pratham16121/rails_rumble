class QuizParticipant < ApplicationRecord
  belongs_to :quiz_session
  has_many :player_answers, dependent: :destroy

  enum :status, { waiting: 0, playing: 1, disconnected: 2 }

  validates :nickname, presence: true, length: { maximum: 30 }
  validates :session_token_digest, presence: true
  validates :joined_at, presence: true
end
