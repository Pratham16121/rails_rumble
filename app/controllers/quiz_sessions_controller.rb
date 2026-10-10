class QuizSessionsController < ApplicationController
  before_action :set_quiz_session, except: %i[ new create ]
  before_action :authorize_host!, except: %i[ new create ]
  before_action :set_templates, only: %i[ new create ]

  def new
    if (@template = QuizTemplate.find(params[:template]))
      @quiz_session = @template.build_quiz_session
      flash.now[:notice] = "Loaded #{@template.title}. Tweak anything you like, then create the quiz."
    else
      @quiz_session = QuizSession.new
      # Add a default question so the form isn't empty
      q = @quiz_session.quiz_questions.build(position: 1, points: 1000, time_limit_seconds: 30)
      4.times { |i| q.question_options.build(position: i + 1) }
    end
  end

  def create
    @quiz_session = QuizSession.new(quiz_session_params)
    result = CreateQuizSession.call(quiz_session: @quiz_session)

    if result[:success]
      remember_token(:host_tokens, @quiz_session.id, result[:host_token])
      redirect_to host_control_quiz_session_path(@quiz_session), notice: "Quiz created! Share the join code with your players."
    else
      render :new, status: :unprocessable_content
    end
  end

  def host_control
    # Host's private view
  end

  # Checked by sync_controller.js after reconnecting, to catch missed live updates
  def state
    render plain: @quiz_session.host_sync_key
  end

  def start
    perform_host_action StartQuiz
  end

  def advance_question
    perform_host_action AdvanceQuestion
  end

  def reveal_answer
    perform_host_action RevealAnswer
  end

  def finish
    perform_host_action FinishQuiz
  end

  private

  def perform_host_action(service)
    result = service.call(quiz_session: @quiz_session)

    if result[:error]
      redirect_to host_control_quiz_session_path(@quiz_session), alert: result[:error]
    else
      @quiz_session.broadcast_to_players
      redirect_to host_control_quiz_session_path(@quiz_session)
    end
  end

  def set_quiz_session
    @quiz_session = QuizSession.find(params[:id])
  end

  def set_templates
    @templates = QuizTemplate.all
  end

  def authorize_host!
    unless @quiz_session.valid_host_token?(remembered_token(:host_tokens, @quiz_session.id))
      redirect_to root_path, alert: "Not authorized"
    end
  end

  def quiz_session_params
    params.require(:quiz_session).permit(
      :title,
      quiz_questions_attributes: [
        :id, :question_text, :position, :points, :time_limit_seconds, :correct_position, :_destroy,
        question_options_attributes: [ :id, :option_text, :position, :_destroy ]
      ]
    )
  end
end
