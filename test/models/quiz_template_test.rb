require "test_helper"

class QuizTemplateTest < ActiveSupport::TestCase
  test "every ready-made quiz can be created as-is" do
    QuizTemplate.all.each do |template|
      quiz_session = template.build_quiz_session

      assert CreateQuizSession.call(quiz_session: quiz_session)[:success],
        "#{template.key}: #{quiz_session.errors.full_messages.to_sentence}"
    end
  end

  test "the Rails quiz has 15 questions with the right answers marked" do
    quiz_session = QuizTemplate.find("rails_for_beginners").build_quiz_session
    CreateQuizSession.call(quiz_session: quiz_session)
    questions = quiz_session.quiz_questions.reload

    assert_equal 15, questions.size
    assert_equal "Puma", questions.first.correct_option.option_text
    assert_equal "people", questions.find_by!(position: 10).correct_option.option_text
    assert_equal 2000, questions.find_by!(position: 10).points
  end

  test "only files in the quizzes folder can be found" do
    assert_nil QuizTemplate.find("../../config/database")
    assert_nil QuizTemplate.find(nil)
  end

  test "a correct answer that isn't one of the answers is reported clearly" do
    template = QuizTemplate.new("broken", "title" => "Broken", "questions" => [
      { "question" => "Pick one", "answers" => %w[ A B C D ], "correct" => "E" }
    ])

    error = assert_raises(ArgumentError) { template.build_quiz_session }
    assert_match "isn't one of its answers", error.message
  end
end
