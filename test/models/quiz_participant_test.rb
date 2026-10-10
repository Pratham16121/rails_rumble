require "test_helper"

class QuizParticipantTest < ActiveSupport::TestCase
  setup do
    @quiz_session, _ = create_quiz
  end

  test "nicknames are trimmed and unique within a quiz, ignoring case" do
    assert_equal "Ada Lovelace", join_quiz(@quiz_session, "  Ada   Lovelace ").nickname

    result = JoinQuizSession.call(join_code: @quiz_session.join_code, nickname: "ada lovelace")
    assert_equal "Nickname is already taken in this quiz", result[:error]
  end

  test "the same nickname can be used in a different quiz" do
    other_quiz, _ = create_quiz
    join_quiz(@quiz_session, "Ada")

    assert join_quiz(other_quiz, "Ada").persisted?
  end

  test "visible score hides points for the current question until the answer is revealed" do
    participant = join_quiz(@quiz_session, "Ada")
    StartQuiz.call(quiz_session: @quiz_session)
    question = @quiz_session.current_question

    SubmitAnswer.call(quiz_participant: participant.reload, question_option_id: option(question, "A").id)
    participant.reload

    assert_equal 10, participant.total_score
    assert_equal 0, participant.visible_score

    RevealAnswer.call(quiz_session: @quiz_session)
    assert_equal 10, participant.reload.visible_score
  end
end
