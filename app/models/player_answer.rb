class PlayerAnswer < ApplicationRecord
  # From the third correct answer in a row, each one earns a bonus that grows with the streak
  STREAK_BONUS = 100
  MAX_STREAK_BONUS = 500

  def self.streak_bonus(streak)
    (STREAK_BONUS * (streak - 2)).clamp(0, MAX_STREAK_BONUS)
  end

  belongs_to :quiz_participant
  belongs_to :quiz_question
  belongs_to :question_option, optional: true

  validates :quiz_participant_id, uniqueness: { scope: :quiz_question_id }
  validates :correct, inclusion: { in: [ true, false ] }

  def streak_bonus
    self.class.streak_bonus(streak)
  end
end
