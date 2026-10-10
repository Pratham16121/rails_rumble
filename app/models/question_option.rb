class QuestionOption < ApplicationRecord
  belongs_to :quiz_question

  validates :option_text, presence: true
  validates :position, presence: true, uniqueness: { scope: :quiz_question_id }
  validates :correct, inclusion: { in: [ true, false ] }
end
