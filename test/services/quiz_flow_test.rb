require "test_helper"

class QuizFlowTest < ActiveSupport::TestCase
  test "full quiz lifecycle" do
    quiz_session, host_token = create_quiz(questions: 2)

    assert quiz_session.persisted?
    assert quiz_session.waiting?
    assert quiz_session.valid_host_token?(host_token)

    participant = join_quiz(quiz_session, "Player1")
    assert participant.persisted?

    assert StartQuiz.call(quiz_session: quiz_session)[:success]
    assert quiz_session.reload.in_progress?
    assert participant.reload.playing?
    first, second = quiz_session.quiz_questions.to_a
    assert_equal first, quiz_session.current_question

    assert SubmitAnswer.call(quiz_participant: participant, question_option_id: option(first, "A").id)[:success]
    assert_equal 10, participant.reload.total_score

    assert RevealAnswer.call(quiz_session: quiz_session)[:success]
    assert AdvanceQuestion.call(quiz_session: quiz_session)[:success]
    assert_equal second, quiz_session.reload.current_question
    assert_not quiz_session.answer_revealed?

    assert SubmitAnswer.call(quiz_participant: participant.reload, question_option_id: option(second, "B").id)[:success]
    assert_equal 10, participant.reload.total_score

    AdvanceQuestion.call(quiz_session: quiz_session)
    assert quiz_session.reload.finished?
    assert_nil quiz_session.current_question
  end

  test "faster correct answers score more points" do
    freeze_time # so the travels below land on exact seconds
    quiz_session, _ = create_quiz(questions: 2, points: 1000, time_limit_seconds: 30)
    quick, slow, wrong = %w[ Quick Slow Wrong ].map { |nickname| join_quiz(quiz_session, nickname) }
    StartQuiz.call(quiz_session: quiz_session)
    question = quiz_session.current_question

    travel(3.seconds) { SubmitAnswer.call(quiz_participant: quick.reload, question_option_id: option(question, "A").id) }
    travel(15.seconds) { SubmitAnswer.call(quiz_participant: slow.reload, question_option_id: option(question, "A").id) }
    travel(1.second) { SubmitAnswer.call(quiz_participant: wrong.reload, question_option_id: option(question, "B").id) }

    assert_equal 950, quick.reload.total_score
    assert_equal 750, slow.reload.total_score
    assert_equal 0, wrong.reload.total_score

    assert_equal 3000, quick.player_answers.sole.response_time_ms
    assert_equal 1000, wrong.player_answers.sole.response_time_ms
  end

  test "streaks of three or more earn a bonus, and the final question is worth double" do
    freeze_time
    quiz_session, _ = create_quiz(questions: 4, points: 1000)
    ada = join_quiz(quiz_session, "Ada")
    StartQuiz.call(quiz_session: quiz_session)

    awarded = 4.times.map do
      question = quiz_session.reload.current_question
      SubmitAnswer.call(quiz_participant: ada.reload, question_option_id: option(question, "A").id)
      RevealAnswer.call(quiz_session: quiz_session)
      AdvanceQuestion.call(quiz_session: quiz_session)
      ada.player_answers.find_by!(quiz_question: question).then { |answer| [ answer.streak, answer.points_awarded ] }
    end

    # Instant answers score full points; the 4th question is the double-points finale
    assert_equal [ [ 1, 1000 ], [ 2, 1000 ], [ 3, 1100 ], [ 4, 2200 ] ], awarded
    assert_equal 5300, ada.reload.total_score
  end

  test "a wrong or missed answer breaks the streak" do
    quiz_session, _ = create_quiz(questions: 4, points: 1000)
    ada = join_quiz(quiz_session, "Ada")
    StartQuiz.call(quiz_session: quiz_session)
    picks = [ "A", "B", nil, "A" ]

    picks.each do |pick|
      question = quiz_session.reload.current_question
      SubmitAnswer.call(quiz_participant: ada.reload, question_option_id: option(question, pick).id) if pick
      RevealAnswer.call(quiz_session: quiz_session)
      AdvanceQuestion.call(quiz_session: quiz_session) unless question.final?
    end

    assert_equal [ 1, 0, 1 ], ada.player_answers.joins(:quiz_question).order("quiz_questions.position").pluck(:streak)
  end

  test "players can't join with an unknown code or after the quiz starts" do
    quiz_session, _ = create_quiz

    assert_equal "We couldn't find a quiz with that code", JoinQuizSession.call(join_code: "NOPE00", nickname: "Ada")[:error]
    assert_equal "We couldn't find a quiz with that code", JoinQuizSession.call(join_code: nil, nickname: "Ada")[:error]

    StartQuiz.call(quiz_session: quiz_session)
    assert_equal "That quiz has already started", JoinQuizSession.call(join_code: quiz_session.join_code, nickname: "Ada")[:error]
  end

  test "join codes are matched regardless of case and surrounding spaces" do
    quiz_session, _ = create_quiz

    result = JoinQuizSession.call(join_code: " #{quiz_session.join_code.downcase} ", nickname: "Ada")
    assert result[:quiz_participant].persisted?
  end

  test "a blank or overlong nickname is an error, not an exception" do
    quiz_session, _ = create_quiz

    assert_equal "Nickname can't be blank", JoinQuizSession.call(join_code: quiz_session.join_code, nickname: "   ")[:error]
    assert_match "too long", JoinQuizSession.call(join_code: quiz_session.join_code, nickname: "x" * 31)[:error]
  end

  test "each player can answer a question only once" do
    quiz_session, _ = create_quiz
    participant = join_quiz(quiz_session, "Ada")
    StartQuiz.call(quiz_session: quiz_session)
    question = quiz_session.current_question

    SubmitAnswer.call(quiz_participant: participant.reload, question_option_id: option(question, "A").id)
    result = SubmitAnswer.call(quiz_participant: participant.reload, question_option_id: option(question, "B").id)

    assert_equal "You've already answered this question", result[:error]
    assert_equal 10, participant.reload.total_score
  end

  test "answers are rejected once the answer is revealed" do
    quiz_session, _ = create_quiz
    participant = join_quiz(quiz_session, "Ada")
    StartQuiz.call(quiz_session: quiz_session)
    RevealAnswer.call(quiz_session: quiz_session)

    result = SubmitAnswer.call(quiz_participant: participant.reload, question_option_id: option(quiz_session.current_question, "A").id)

    assert_equal "Answers are closed for this question", result[:error]
    assert_equal 0, participant.reload.total_score
  end

  test "answers are rejected after the time limit" do
    quiz_session, _ = create_quiz(time_limit_seconds: 10)
    participant = join_quiz(quiz_session, "Ada")
    StartQuiz.call(quiz_session: quiz_session)

    travel 15.seconds do
      result = SubmitAnswer.call(quiz_participant: participant.reload, question_option_id: option(quiz_session.current_question, "A").id)
      assert_equal "Answers are closed for this question", result[:error]
    end
  end

  test "an option from another question is rejected" do
    quiz_session, _ = create_quiz(questions: 2)
    participant = join_quiz(quiz_session, "Ada")
    StartQuiz.call(quiz_session: quiz_session)
    other_question = quiz_session.quiz_questions.last

    result = SubmitAnswer.call(quiz_participant: participant.reload, question_option_id: option(other_question, "A").id)
    assert_equal "Invalid option", result[:error]
  end

  test "host actions only apply in the right state" do
    quiz_session, _ = create_quiz

    assert_equal "Quiz not in progress", RevealAnswer.call(quiz_session: quiz_session)[:error]
    assert_equal "Quiz not in progress", AdvanceQuestion.call(quiz_session: quiz_session)[:error]
    assert_equal "Quiz not in progress", FinishQuiz.call(quiz_session: quiz_session)[:error]

    StartQuiz.call(quiz_session: quiz_session)
    assert_equal "Quiz is not waiting", StartQuiz.call(quiz_session: quiz_session)[:error]

    RevealAnswer.call(quiz_session: quiz_session)
    assert_equal "Answer already revealed", RevealAnswer.call(quiz_session: quiz_session)[:error]
  end
end
