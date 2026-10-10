class QuizSession < ApplicationRecord
  # Answers sent just after the timer runs out still count, to absorb network latency.
  ANSWER_GRACE_PERIOD = 1.second

  has_many :quiz_questions, -> { order(:position) }, dependent: :destroy
  has_many :quiz_participants, dependent: :destroy
  belongs_to :current_question, class_name: "QuizQuestion", optional: true

  accepts_nested_attributes_for :quiz_questions, allow_destroy: true

  enum :status, { waiting: 0, in_progress: 1, finished: 2 }

  before_validation :apply_correct_positions

  validates :title, presence: true, length: { maximum: 100 }
  validates :join_code, presence: true, uniqueness: true
  validates :host_token_digest, presence: true

  validate :questions_must_be_valid

  def valid_host_token?(token)
    SecretToken.matches?(token, host_token_digest)
  end

  def next_question
    quiz_questions.where("position > ?", current_question.position).first if current_question
  end

  def question_ends_at
    question_started_at + current_question.time_limit_seconds if current_question && question_started_at
  end

  def seconds_remaining
    return 0 unless question_ends_at

    [ question_ends_at - Time.current, 0 ].max.round(1)
  end

  def accepting_answers?
    in_progress? && !answer_revealed? && question_ends_at.present? &&
      Time.current <= question_ends_at + ANSWER_GRACE_PERIOD
  end

  # [rank, participant] pairs, best first. Tied scores share a rank.
  def leaderboard
    ranked = quiz_participants.sort_by { |participant| [ -participant.total_score, participant.joined_at ] }
    ranked.map do |participant|
      [ ranked.index { |other| other.total_score == participant.total_score } + 1, participant ]
    end
  end

  # Short keys for what each screen shows. Live updates sent while a page is reloading or a phone
  # is asleep are lost, so after (re)connecting, a page asks for the current key and reloads if
  # it's behind (see sync_controller.js). Each key matches a data-sync-key attribute on the page.
  def player_sync_key
    [ status, current_question_id, answer_revealed? ].join(":")
  end

  def host_game_sync_key
    [ status, current_question_id, answer_revealed?, quiz_participants.size ].join(":")
  end

  def answer_count
    current_question.player_answers.count
  end

  def everyone_answered?
    in_progress? && current_question.present? && answer_count >= quiz_participants.count
  end

  # Every key on the host screen, in page order: the game panel, then the answer count while a question is live.
  def host_sync_key
    [ host_game_sync_key, (answer_count if in_progress? && current_question) ].compact.join("|")
  end

  # Pushes a new game state to every player's phone. The host's screen updates from the
  # redirect after their own action, so broadcasting to it too would render it twice.
  def broadcast_to_players
    quiz_participants.each(&:broadcast_game)
  end

  # Re-renders the host's screen when a player joins. Only the new player's chip is
  # flagged, so it pops in without replaying the animation for everyone else.
  def broadcast_host_view(new_participant: nil)
    broadcast_replace_to [ self, :host ], target: "host_game",
      partial: "quiz_sessions/host_game", locals: { quiz_session: self, new_participant: new_participant }
  end

  # Updates just the answer count and the "locked in" lane, leaving the rest of the host's
  # screen alone. Only the newest player's avatar is flagged, so only it pops in.
  def broadcast_answer_count(new_participant: nil)
    broadcast_replace_to [ self, :host ], target: "answer_count",
      partial: "quiz_sessions/answer_count", locals: { quiz_session: self, new_participant: new_participant }
  end

  private

  def apply_correct_positions
    quiz_questions.each(&:apply_correct_position)
  end

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
