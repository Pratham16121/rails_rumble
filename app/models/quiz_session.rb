class QuizSession < ApplicationRecord
  has_many :quiz_questions, dependent: :destroy
  has_many :quiz_participants, dependent: :destroy
  belongs_to :current_question, class_name: 'QuizQuestion', optional: true

  accepts_nested_attributes_for :quiz_questions, allow_destroy: true

  enum :status, { waiting: 0, in_progress: 1, finished: 2 }

  validates :title, presence: true
  validates :join_code, presence: true, uniqueness: true
  validates :host_token_digest, presence: true

  validate :questions_must_be_valid

  private

  def questions_must_be_valid
    active_questions = quiz_questions.reject(&:marked_for_destruction?)
    
    if active_questions.empty?
      errors.add(:base, "You must provide at least one question")
      return
    end

    active_questions.each_with_index do |q, index|
      active_options = q.question_options.reject(&:marked_for_destruction?)
      if active_options.size != 4
        errors.add(:base, "Question #{index + 1} must have exactly four options")
      end
      
      if active_options.count { |o| o.correct? } != 1
        errors.add(:base, "Question #{index + 1} must have exactly one correct option")
      end
    end
  end
end
