require "application_system_test_case"

class QuizGameTest < ApplicationSystemTestCase
  test "a host and a player play a full quiz in real time" do
    visit root_path
    click_on "Host a quiz"
    fill_in "Title", with: "Capitals"
    within all(".question-fields")[0] do
      fill_in "Question", with: "Capital of France?"
      %w[ Berlin Madrid Paris Rome ].each.with_index(1) { |text, i| fill_in "Option #{i}", with: text }
      choose option: "3"
    end
    click_on "+ Add question"
    within all(".question-fields", count: 2)[1] do
      assert_text "Question 2"
      fill_in "Question", with: "Capital of Japan?"
      fill_in "Time limit (seconds)", with: 2
      %w[ Tokyo Osaka Kyoto Nara ].each.with_index(1) { |text, i| fill_in "Option #{i}", with: text }
      choose option: "1"
    end
    click_on "Create quiz"

    assert_text "Quiz created!"
    join_code = QuizSession.last.join_code
    connect_turbo_cable_stream_sources

    using_session(:player) do
      visit join_path
      fill_in "Quiz code", with: join_code.downcase
      fill_in "Your nickname", with: "Ada"
      click_on "Let's go!"
      assert_text "You're in!"
    end

    # The player shows up on the host's screen without a reload
    assert_selector ".participant-list li", text: "Ada"
    click_on "Start quiz"
    assert_text(/Question 1 of 2/i)
    connect_turbo_cable_stream_sources

    # Ada is the only player, so her answer reveals the result straight away
    using_session(:player) do
      assert_text "Capital of France?"
      click_on "Paris"
      assert_text(/Correct! \+\d+ points/)
      assert_text "⚡ Fastest finger!"
      assert_text(/You answered in \d+\.\ds/)
      assert_no_selector ".player-score", text: /\A0 pts\z/
      connect_turbo_cable_stream_sources
    end

    assert_text "1 of 1 player answered"
    assert_selector ".locked-in li", text: "Ada"
    assert_selector ".option.correct", text: "Paris"
    assert_selector ".option-votes", text: "1"
    assert_selector ".fastest-finger", text: "Ada"

    click_on "Next question"
    assert_text(/Question 2 of 2/i)
    connect_turbo_cable_stream_sources

    assert_text(/Final question · double points!/i)
    using_session(:player) do
      assert_text "Capital of Japan?"
      assert_text(/Final question · double points!/i)
      assert_text "Time's up!", wait: 5
      assert_no_button "Tokyo"
    end

    # Nobody answered, so the host's countdown reveals the answer when time runs out
    using_session(:player) do
      assert_text "No answer this time", wait: 8
      assert_text "The answer was Tokyo"
    end

    click_on "Show final results"
    assert_text "Final results"
    assert_text "and the winner is", wait: 5

    using_session(:player) do
      assert_text(/Quiz finished!/i)
      assert_text "eyes on the big screen"
      assert_text "You placed 1st", wait: 8
      assert_selector ".leaderboard li.you", text: "Ada", wait: 8
    end
  end

  test "a host loads the Rails quiz and starts it" do
    visit start_path
    click_on "Rails for Beginners"
    assert_text "Loaded Rails for Beginners"
    assert_selector ".question-fields", count: 15
    click_on "Create quiz"

    assert_text "Quiz created!"
    quiz_session = QuizSession.last
    assert_equal 15, quiz_session.quiz_questions.count
    assert_equal "Puma", quiz_session.quiz_questions.first.correct_option.option_text

    JoinQuizSession.call(join_code: quiz_session.join_code, nickname: "Ada")
    visit current_path
    click_on "Start quiz"
    assert_text "What's the name of the application server that ships with Rails?"
    assert_text "Cheetah"
  end

  test "a player who missed a live update catches up when their phone wakes" do
    quiz_session, _ = create_quiz(questions: 1)
    visit join_path(join_code: quiz_session.join_code)
    fill_in "Your nickname", with: "Ada"
    click_on "Let's go!"
    assert_text "You're in!"

    # Start without broadcasting, as if the phone was asleep when the update went out
    StartQuiz.call(quiz_session: quiz_session)
    assert_text "You're in!"

    page.execute_script("document.dispatchEvent(new Event('visibilitychange'))")
    assert_text "Q1"
    assert_button "A"
  end
end
