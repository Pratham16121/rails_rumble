require "test_helper"

class QuizGameTest < ActionDispatch::IntegrationTest
  test "a host creates a quiz and marks correct answers with the radio buttons" do
    post quiz_sessions_path, params: { quiz_session: {
      title: "Capitals",
      quiz_questions_attributes: { "0" => {
        question_text: "Capital of France?", position: 1, points: 10, time_limit_seconds: 20, correct_position: 3,
        question_options_attributes: %w[ Berlin Madrid Paris Rome ].each_with_index.to_h { |text, i|
          [ i.to_s, { option_text: text, position: i + 1 } ]
        }
      } }
    } }

    quiz_session = QuizSession.last
    assert_redirected_to host_control_quiz_session_path(quiz_session)
    assert_equal "Paris", quiz_session.quiz_questions.first.correct_option.option_text

    follow_redirect!
    assert_response :success
    assert_select ".join-code", quiz_session.join_code
    assert_select ".join-qr svg"
  end

  test "the builder can be pre-filled with a ready-made quiz" do
    get start_path(template: "rails_for_beginners")

    assert_response :success
    assert_select "input[name='quiz_session[title]'][value=?]", "Rails for Beginners"
    assert_select "[data-nested-form-target=target] .question-fields", 15
    assert_select "input[type=radio][checked]", 15
    assert_select ".template-chip.active", /Rails for Beginners/
  end

  test "an unknown ready-made quiz falls back to a blank builder" do
    get start_path(template: "nope")

    assert_response :success
    assert_select "[data-nested-form-target=target] .question-fields", 1
  end

  test "an invalid quiz re-renders the form with errors" do
    post quiz_sessions_path, params: { quiz_session: { title: "Nothing here" } }

    assert_response :unprocessable_content
    assert_select ".alert-error", /at least one question/
  end

  test "only the host's browser can control the quiz" do
    quiz_session, _ = create_quiz

    get host_control_quiz_session_path(quiz_session)
    assert_redirected_to root_path

    post start_quiz_session_path(quiz_session)
    assert_redirected_to root_path
    assert quiz_session.reload.waiting?
  end

  test "one browser can host several quizzes at once" do
    first = host_quiz("First")
    second = host_quiz("Second")

    get host_control_quiz_session_path(first)
    assert_response :success
    get host_control_quiz_session_path(second)
    assert_response :success
  end

  test "joining with a blank nickname shows an error instead of crashing" do
    quiz_session, _ = create_quiz

    post quiz_participants_path, params: { quiz_participant: { join_code: quiz_session.join_code, nickname: "  " } }

    assert_response :unprocessable_content
    assert_select ".alert-alert", "Nickname can't be blank"
    assert_select "input[name='quiz_participant[join_code]'][value=?]", quiz_session.join_code
  end

  test "joining without the form fields is a bad request" do
    post quiz_participants_path
    assert_response :bad_request
  end

  test "a player plays through a question" do
    quiz_session, _ = create_quiz(questions: 2)
    join_quiz(quiz_session, "Bob") # still to answer, so the reveal waits for the host
    post quiz_participants_path, params: { quiz_participant: { join_code: quiz_session.join_code, nickname: "Ada" } }
    participant = quiz_session.quiz_participants.last
    assert_redirected_to quiz_participant_path(participant)

    StartQuiz.call(quiz_session: quiz_session)
    question = quiz_session.current_question
    post submit_answer_quiz_participant_path(participant), params: { question_option_id: option(question, "A").id }
    follow_redirect!

    assert_select ".status-panel", /You picked A/
    assert_select ".answer-speed", /locked in after \d+\.\ds/
    assert_select ".player-score", "0 pts", "points stay hidden until the reveal"

    RevealAnswer.call(quiz_session: quiz_session)
    get quiz_participant_path(participant)
    assert_select ".result-correct", /Correct!/
    assert_select ".player-score", "10 pts"
  end

  test "the answer is revealed as soon as the last player locks in" do
    quiz_session, _ = create_quiz(questions: 2)
    ada, bob = open_session, open_session
    [ [ ada, "Ada" ], [ bob, "Bob" ] ].each do |player, nickname|
      player.post quiz_participants_path, params: { quiz_participant: { join_code: quiz_session.join_code, nickname: nickname } }
    end
    StartQuiz.call(quiz_session: quiz_session)
    question = quiz_session.reload.current_question

    [ ada, bob ].zip(quiz_session.quiz_participants.order(:joined_at)).each do |player, participant|
      assert_not quiz_session.reload.answer_revealed?
      player.post submit_answer_quiz_participant_path(participant), params: { question_option_id: option(question, "A").id }
    end

    assert quiz_session.reload.answer_revealed?
  end

  test "players can't see each other's game" do
    quiz_session, _ = create_quiz
    ada = join_quiz(quiz_session, "Ada")

    get quiz_participant_path(ada)
    assert_redirected_to root_path
  end

  test "each screen's sync keys match its state endpoint in every game state" do
    quiz_session = host_quiz("Sync")
    player = open_session
    player.post quiz_participants_path, params: { quiz_participant: { join_code: quiz_session.join_code, nickname: "Ada" } }
    participant = quiz_session.quiz_participants.last

    assert_in_sync = lambda do
      get host_control_quiz_session_path(quiz_session)
      host_page = sync_keys(response.body)
      get state_quiz_session_path(quiz_session)
      assert_equal response.body, host_page

      player.get quiz_participant_path(participant)
      player_page = sync_keys(player.response.body)
      player.get state_quiz_participant_path(participant)
      assert_equal player.response.body, player_page
    end

    assert_in_sync.call
    post start_quiz_session_path(quiz_session)
    assert_in_sync.call
    player.post submit_answer_quiz_participant_path(participant),
      params: { question_option_id: quiz_session.reload.current_question.question_options.first.id }
    assert_in_sync.call
    post reveal_answer_quiz_session_path(quiz_session)
    assert_in_sync.call
    post advance_question_quiz_session_path(quiz_session)
    assert quiz_session.reload.finished?
    assert_in_sync.call
  end

  test "state endpoints need the host's or player's token" do
    quiz_session, _ = create_quiz
    ada = join_quiz(quiz_session, "Ada")

    get state_quiz_session_path(quiz_session)
    assert_redirected_to root_path
    get state_quiz_participant_path(ada)
    assert_redirected_to root_path
  end

  private

  def host_quiz(title)
    post quiz_sessions_path, params: { quiz_session: {
      title: title,
      quiz_questions_attributes: { "0" => {
        question_text: "Q", position: 1, points: 10, time_limit_seconds: 20, correct_position: 1,
        question_options_attributes: (1..4).to_h { |i| [ i.to_s, { option_text: "O#{i}", position: i } ] }
      } }
    } }
    QuizSession.last
  end

  def sync_keys(html)
    Nokogiri::HTML(html).css("[data-controller=sync] [data-sync-key]").map { |element| element["data-sync-key"] }.join("|")
  end
end
