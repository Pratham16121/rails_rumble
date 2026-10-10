ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Builds and saves a quiz whose questions each have options "A".."D", with "A" correct.
    # Returns the quiz session and its host token.
    def create_quiz(title: "Test Quiz", questions: 2, points: 10, time_limit_seconds: 30)
      quiz_session = QuizSession.new(title: title)
      questions.times do |i|
        question = quiz_session.quiz_questions.build(question_text: "Q#{i + 1}", position: i + 1,
          points: points, time_limit_seconds: time_limit_seconds, correct_position: 1)
        %w[ A B C D ].each.with_index(1) { |text, position| question.question_options.build(option_text: text, position: position) }
      end

      result = CreateQuizSession.call(quiz_session: quiz_session)
      [ quiz_session, result[:host_token] ]
    end

    def join_quiz(quiz_session, nickname)
      JoinQuizSession.call(join_code: quiz_session.join_code, nickname: nickname)[:quiz_participant]
    end

    def option(question, text)
      question.question_options.find_by!(option_text: text)
    end
  end
end
