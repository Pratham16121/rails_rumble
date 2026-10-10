class QuizSessionsController < ApplicationController
  before_action :set_quiz_session, only: [:show, :host_control, :start, :advance_question, :reveal_answer, :finish]
  before_action :authorize_host!, only: [:host_control, :start, :advance_question, :reveal_answer, :finish]

  def new
    @quiz_session = QuizSession.new
    # Add a default question so the form isn't empty
    q = @quiz_session.quiz_questions.build(position: 1, points: 10, time_limit_seconds: 30)
    4.times { |i| q.question_options.build(position: i + 1) }
  end

  def create
    @quiz_session = QuizSession.new(quiz_session_params)
    result = CreateQuizSession.call(quiz_session: @quiz_session)
    
    if result[:success]
      session[:host_token] = result[:host_token]
      redirect_to host_control_quiz_session_path(@quiz_session), notice: 'Quiz created!'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    # Waiting room / participant view for the session
    # Handled mainly via participants controller for joining, but if they hit this directly:
  end

  def host_control
    # Host's private view
  end

  def start
    result = StartQuiz.call(quiz_session: @quiz_session, host_token: session[:host_token])
    if result[:error]
      redirect_to host_control_quiz_session_path(@quiz_session), alert: result[:error]
    else
      broadcast_updates
      redirect_to host_control_quiz_session_path(@quiz_session)
    end
  end

  def advance_question
    result = AdvanceQuestion.call(quiz_session: @quiz_session, host_token: session[:host_token])
    if result[:error]
      redirect_to host_control_quiz_session_path(@quiz_session), alert: result[:error]
    else
      broadcast_updates
      redirect_to host_control_quiz_session_path(@quiz_session)
    end
  end

  def reveal_answer
    correct_option = @quiz_session.current_question.question_options.find_by(correct: true)
    
    ActionCable.server.broadcast("quiz_session_#{@quiz_session.id}", 
      "<turbo-stream action=\"append\" target=\"participant-container\"><template><script>
        document.querySelectorAll('.option-btn').forEach(btn => {
          if (btn.textContent.trim() === '#{ActionController::Base.helpers.j(correct_option.option_text)}') {
            btn.style.background = 'var(--accent)';
          } else {
            btn.style.opacity = '0.5';
          }
        });
      </script></template></turbo-stream>")
    
    redirect_to host_control_quiz_session_path(@quiz_session)
  end

  def finish
    result = FinishQuiz.call(quiz_session: @quiz_session)
    if result[:error]
      redirect_to host_control_quiz_session_path(@quiz_session), alert: result[:error]
    else
      broadcast_updates
      redirect_to host_control_quiz_session_path(@quiz_session)
    end
  end

  private

  def broadcast_updates
    state = "#{@quiz_session.status}-#{@quiz_session.current_question_id}-#{Time.current.to_i}"
    
    ActionCable.server.broadcast("quiz_session_#{@quiz_session.id}_host", 
      "<turbo-stream action=\"update\" target=\"quiz-state-host\"><template>#{state}</template></turbo-stream>")

    ActionCable.server.broadcast("quiz_session_#{@quiz_session.id}", 
      "<turbo-stream action=\"update\" target=\"quiz-state\"><template>#{state}</template></turbo-stream>")
  end

  def set_quiz_session
    @quiz_session = QuizSession.find(params[:id])
  end

  def authorize_host!
    token = session[:host_token]
    unless token && Digest::SHA256.hexdigest(token) == @quiz_session.host_token_digest
      redirect_to root_path, alert: 'Not authorized'
    end
  end

  def quiz_session_params
    params.require(:quiz_session).permit(
      :title,
      quiz_questions_attributes: [
        :id, :question_text, :position, :points, :time_limit_seconds, :_destroy,
        question_options_attributes: [:id, :option_text, :position, :correct, :_destroy]
      ]
    )
  end
end
