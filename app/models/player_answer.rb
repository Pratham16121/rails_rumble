class PlayerAnswer < ApplicationRecord
  belongs_to :quiz_participant
  belongs_to :quiz_question
  belongs_to :question_option, optional: true

  validates :quiz_participant_id, uniqueness: { scope: :quiz_question_id }
  validates :correct, inclusion: { in: [true, false] }
end
