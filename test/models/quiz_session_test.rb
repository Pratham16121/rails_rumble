require "test_helper"

class QuizSessionTest < ActiveSupport::TestCase
  test "requires at least one question" do
    quiz_session = QuizSession.new(title: "Empty")

    assert_not CreateQuizSession.call(quiz_session: quiz_session)[:success]
    assert_includes quiz_session.errors[:base], "You must provide at least one question"
  end

  test "requires a correct option on every question" do
    quiz_session = QuizSession.new(title: "No answer")
    question = quiz_session.quiz_questions.build(question_text: "Q", position: 1, points: 10, time_limit_seconds: 30)
    4.times { |i| question.question_options.build(option_text: "O#{i}", position: i + 1) }

    assert_not CreateQuizSession.call(quiz_session: quiz_session)[:success]
    assert_includes quiz_session.errors[:base], "Question 1 must have exactly one correct option"
  end

  test "correct_position marks exactly that option as correct" do
    quiz_session, _ = create_quiz(questions: 1)
    question = quiz_session.quiz_questions.first

    assert_equal [ true, false, false, false ], question.question_options.map(&:correct)
    assert_equal option(question, "A"), question.correct_option
  end

  test "join codes avoid lookalike characters" do
    20.times do
      assert_match(/\A[A-HJKMNP-Z2-9]{6}\z/, CreateQuizSession.generate_join_code)
    end
  end

  test "accepts answers only until time runs out or the answer is revealed" do
    quiz_session, _ = create_quiz(time_limit_seconds: 10)
    StartQuiz.call(quiz_session: quiz_session)

    assert quiz_session.accepting_answers?

    travel 10.seconds + QuizSession::ANSWER_GRACE_PERIOD do
      assert quiz_session.accepting_answers?, "answers sent within the grace period should count"
    end

    travel 12.seconds do
      assert_not quiz_session.accepting_answers?
      assert_equal 0, quiz_session.seconds_remaining
    end

    RevealAnswer.call(quiz_session: quiz_session)
    assert_not quiz_session.accepting_answers?
  end

  test "leaderboard ranks by score and tied players share a rank" do
    quiz_session, _ = create_quiz
    ada = join_quiz(quiz_session, "Ada")
    bob = join_quiz(quiz_session, "Bob")
    cy = join_quiz(quiz_session, "Cy")
    ada.update!(total_score: 20)
    bob.update!(total_score: 10)
    cy.update!(total_score: 20)

    assert_equal [ [ 1, "Ada" ], [ 1, "Cy" ], [ 3, "Bob" ] ],
      quiz_session.reload.leaderboard.map { |rank, participant| [ rank, participant.nickname ] }
  end
end
