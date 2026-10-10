# A ready-made quiz a host can load into the builder. Each one is a YAML file in config/quizzes.
class QuizTemplate
  DIRECTORY = Rails.root.join("config/quizzes")
  DEFAULT_POINTS = 1000
  DEFAULT_TIME_LIMIT = 20

  attr_reader :key, :title, :emoji, :questions

  def self.all
    DIRECTORY.glob("*.yml").sort.map { |path| new(path.basename(".yml").to_s, YAML.load_file(path)) }
  end

  # Looked up from the list of files rather than by building a path, so a key can't reach outside the folder.
  def self.find(key)
    all.find { |template| template.key == key }
  end

  def initialize(key, data)
    @key = key
    @title = data.fetch("title")
    @emoji = data["emoji"]
    @questions = data.fetch("questions")
  end

  # An unsaved quiz with every question filled in, ready to show in the builder form.
  def build_quiz_session
    QuizSession.new(title: title).tap do |quiz_session|
      questions.each.with_index(1) do |question, position|
        answers = question.fetch("answers")
        correct_index = answers.index(question.fetch("correct")) or
          raise ArgumentError, "#{key}: the correct answer to #{question["question"].inspect} isn't one of its answers"

        quiz_question = quiz_session.quiz_questions.build(
          question_text: question.fetch("question"),
          position: position,
          points: question.fetch("points", DEFAULT_POINTS),
          time_limit_seconds: question.fetch("time_limit", DEFAULT_TIME_LIMIT),
          correct_position: correct_index + 1
        )
        answers.each.with_index(1) do |answer, answer_position|
          quiz_question.question_options.build(option_text: answer, position: answer_position)
        end
      end
    end
  end
end
