class QuizQuestion < ApplicationRecord
  belongs_to :quiz_session
  has_many :player_answers, dependent: :destroy
  has_many :question_options, -> { order(:position) }, dependent: :destroy

  accepts_nested_attributes_for :question_options, allow_destroy: true

  # Set by the quiz form's radio buttons: the position of the correct option.
  attribute :correct_position, :integer

  validates :question_text, presence: true
  validates :position, presence: true, uniqueness: { scope: :quiz_session_id }
  validates :points, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :time_limit_seconds, presence: true, numericality: { greater_than: 0 }

  def correct_option
    question_options.find(&:correct?)
  end

  # The last question is worth double, so a comeback is always possible
  def final?
    quiz_session.present? && position == quiz_session.quiz_questions.maximum(:position)
  end

  def max_points
    final? ? points * 2 : points
  end

  # Fastest fingers first: a correct answer scores the full points when instant,
  # sliding down to half at the buzzer.
  def points_for(response_time)
    (max_points * (1 - (response_time.to_f / time_limit_seconds).clamp(0.0, 1.0) / 2.0)).round
  end

  def fastest_correct_answer
    player_answers.where(correct: true).order(:response_time_ms, :answered_at).first
  end

  def apply_correct_position
    return if correct_position.nil?

    question_options.each { |option| option.correct = option.position == correct_position }
  end
end
