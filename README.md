# Real-Time Quiz

A live multiplayer quiz game, in the spirit of Kahoot. A host builds a quiz and puts it on a big screen; players join from their phones with a six-character code and answer against the clock. No accounts needed.

## How a game works

1. **Host** goes to `/start`, writes questions (four options each, one correct, with points and a time limit), and gets a join code.
2. **Players** go to `/join`, enter the code and a nickname, and wait in the lobby. They appear on the host's screen as they join.
3. **Host** starts the quiz. For each question, players have until the timer runs out to answer. The host sees how many have answered, then reveals the answer and moves on.
4. After the last question, everyone sees the leaderboard.

**Scoring**
- **Fastest fingers first:** a correct answer scores the question's full points if it's instant, sliding down to half at the buzzer (`QuizQuestion#points_for`). Wrong answers score nothing. The reveal names the fastest correct player, and each player sees how quickly they answered.
- **Streaks:** from the third correct answer in a row, each one earns a bonus of +100 per answer beyond two, up to +500 (`PlayerAnswer.streak_bonus`). A wrong or missed answer resets it.
- **The final question is worth double**, announced with a banner on every screen.

**Pacing:** the answer reveals itself as soon as every player has locked in, or when the host's countdown runs out (the host's screen submits the reveal). The host can still reveal early. The reveal shows how many people picked each answer before highlighting the right one, and the results end with a podium: 3rd, 2nd, a drumroll, then the winner. Phones hold back each player's rank until the big screen has shown it.

The lobby shows a QR code that opens the join page with the code filled in.

Points for a question stay hidden from the player until the host reveals the answer, and answers are rejected after the reveal or once time is up (plus a one-second grace period for network lag).

## Running it

Requires Ruby 3.2 (see `.ruby-version`) and SQLite.

```sh
bin/setup      # installs gems, prepares the database, starts the server
bin/dev        # starts the server on http://localhost:3000
```

To try a game on your own, host in one browser and join from a private window or your phone.

## Ready-made quizzes

The builder at `/start` can load a ready-made quiz (there's a 15-question "Rails for Beginners" one) that the host can tweak before creating. Each lives in `config/quizzes/` as a YAML file: a `title`, an optional `emoji`, and `questions` with four `answers` each and the `correct` one. `points` (the most a correct answer can score; default 1000) and `time_limit` in seconds (default 20) are optional. Add a file and it shows up in the builder; `test/models/quiz_template_test.rb` checks that every file builds a valid quiz.

## Tests

```sh
bin/rails test           # models, services, and request tests
bin/rails test:system    # plays a full game in headless Chrome (host and player in separate sessions)
bin/rubocop              # style
bin/brakeman             # security scan
```

## How it's built

Rails 8 with Hotwire, SQLite, and Solid Cable/Queue/Cache. No JavaScript build step.

- **Game rules** live in service objects in `app/services/` (`CreateQuizSession`, `JoinQuizSession`, `StartQuiz`, `SubmitAnswer`, `RevealAnswer`, `AdvanceQuestion`, `FinishQuiz`). Each returns `{ success: true }` or `{ error: "..." }`.
- **Identity** is a random token per quiz for the host and per player, kept in the session cookie. The database stores only a SHA-256 digest. Controllers check the token before every host or player action.
- **Live updates** use Turbo Stream broadcasts over Action Cable. When the host starts, reveals or advances, `QuizSession#broadcast_to_players` re-renders `quiz_participants/_game` for each player (each view is personal: their answer, their score). The host's own screen updates from the redirect after their click; player joins and answers update it through `broadcast_host_view` and `broadcast_answer_count`. Updates are kept this narrow so entrance animations only play when something actually changed.
- **The look** is plain CSS in `application.css`: background doodles (`layouts/_doodles`), generated doodle avatars (`AvatarHelper`), and a `confetti` Stimulus controller. Every animation respects the OS "reduce motion" setting.
- **The countdown** is a small Stimulus controller (`countdown_controller.js`). The server sends the seconds remaining rather than an end time, so device clock differences don't matter. The server enforces the limit independently.

## Deploying

`config/deploy.yml` is set up for [Kamal](https://kamal-deploy.org) but still has placeholder values: set the server IP, image name, registry user, and `proxy.host` before deploying.
