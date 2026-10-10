require "test_helper"

class QuizQuestionTest < ActiveSupport::TestCase
  setup do
    @question = QuizQuestion.new(points: 1000, time_limit_seconds: 20)
  end

  test "faster correct answers score more, from all the points down to half" do
    assert_equal 1000, @question.points_for(0)
    assert_equal 875, @question.points_for(5)
    assert_equal 750, @question.points_for(10)
    assert_equal 500, @question.points_for(20)
  end

  test "the last question is worth double" do
    quiz_session, _ = create_quiz(questions: 3, points: 1000)
    first, _, last = quiz_session.quiz_questions.to_a

    assert_not first.final?
    assert last.final?
    assert_equal 1000, first.points_for(0)
    assert_equal 2000, last.points_for(0)
  end

  test "the streak bonus starts at three in a row and is capped" do
    assert_equal [ 0, 0, 100, 200, 500, 500 ], [ 1, 2, 3, 4, 7, 12 ].map { |streak| PlayerAnswer.streak_bonus(streak) }
  end

  test "answers in the grace period after the buzzer still score half" do
    assert_equal 500, @question.points_for(20.8)
  end

  test "the fastest finger is the quickest correct answer, ignoring quicker wrong ones" do
    freeze_time
    quiz_session, _ = create_quiz(questions: 1, points: 1000)
    ada, bob, cy = %w[ Ada Bob Cy ].map { |nickname| join_quiz(quiz_session, nickname) }
    StartQuiz.call(quiz_session: quiz_session)
    question = quiz_session.current_question

    travel(1.second) { SubmitAnswer.call(quiz_participant: bob.reload, question_option_id: option(question, "B").id) }
    travel(4.seconds) { SubmitAnswer.call(quiz_participant: cy.reload, question_option_id: option(question, "A").id) }
    travel(2.seconds) { SubmitAnswer.call(quiz_participant: ada.reload, question_option_id: option(question, "A").id) }

    assert_equal ada, question.fastest_correct_answer.quiz_participant
  end
end
