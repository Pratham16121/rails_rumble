require "test_helper"

class QuizFlowTest < ActiveSupport::TestCase
  test "full quiz lifecycle" do
    # 1. Create Session
    session = QuizSession.new(title: "Test Quiz")
    q = session.quiz_questions.build(question_text: "Q1", position: 1, points: 10, time_limit_seconds: 30)
    o1 = q.question_options.build(option_text: "A", position: 1, correct: true)
    o2 = q.question_options.build(option_text: "B", position: 2, correct: false)
    o3 = q.question_options.build(option_text: "C", position: 3, correct: false)
    o4 = q.question_options.build(option_text: "D", position: 4, correct: false)
    
    result = CreateQuizSession.call(quiz_session: session)
    host_token = result[:host_token]
    
    assert session.persisted?
    assert session.waiting?
    assert_not_nil session.join_code
    
    # 2. Join Session
    join_result = JoinQuizSession.call(join_code: session.join_code, nickname: "Player1")
    participant = join_result[:quiz_participant]
    player_token = join_result[:player_token]
    
    assert participant.persisted?
    
    # 3. Start Quiz
    start_result = StartQuiz.call(quiz_session: session, host_token: host_token)
    assert start_result[:success]
    assert session.reload.in_progress?
    assert_equal q, session.current_question
    
    # 4. Submit Answer
    participant.reload
    ans_result = SubmitAnswer.call(
      quiz_participant: participant,
      player_token: player_token,
      question_option_id: o1.id
    )
    assert ans_result[:success]
    assert_equal 10, participant.reload.total_score
    
    # 5. Advance/Finish
    finish_result = AdvanceQuestion.call(quiz_session: session, host_token: host_token)
    assert session.reload.finished?
  end
end
