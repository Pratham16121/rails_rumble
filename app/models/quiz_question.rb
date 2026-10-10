class QuizQuestion < ApplicationRecord
  belongs_to :quiz_session
  has_many :question_options, dependent: :destroy
  has_many :player_answers, dependent: :destroy

  accepts_nested_attributes_for :question_options, allow_destroy: true

  validates :question_text, presence: true
  validates :position, presence: true, uniqueness: { scope: :quiz_session_id }
  validates :points, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :time_limit_seconds, presence: true, numericality: { greater_than: 0 }
end
