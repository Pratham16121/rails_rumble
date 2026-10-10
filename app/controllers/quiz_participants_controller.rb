class QuizParticipantsController < ApplicationController
  before_action :set_participant, only: %i[ show submit_answer state ]

  def new
    @join_code = params[:join_code]
  end

  def create
    join_params = params.expect(quiz_participant: [ :join_code, :nickname ])
    result = JoinQuizSession.call(join_code: join_params[:join_code], nickname: join_params[:nickname])

    if result[:error]
      @join_code, @nickname = join_params[:join_code], join_params[:nickname]
      flash.now[:alert] = result[:error]
      render :new, status: :unprocessable_content
    else
      remember_token(:player_tokens, result[:quiz_participant].id, result[:player_token])
      result[:quiz_session].broadcast_host_view(new_participant: result[:quiz_participant])
      redirect_to quiz_participant_path(result[:quiz_participant])
    end
  end

  def show
    # Player's view of the game
  end

  # Checked by sync_controller.js after reconnecting, to catch missed live updates
  def state
    render plain: @quiz_participant.quiz_session.player_sync_key
  end

  def submit_answer
    result = SubmitAnswer.call(quiz_participant: @quiz_participant, question_option_id: params[:question_option_id])

    if result[:error]
      redirect_to quiz_participant_path(@quiz_participant), alert: result[:error]
    else
      quiz_session = @quiz_participant.quiz_session
      # Once the last player locks in there's nothing left to wait for, so reveal straight away
      if quiz_session.everyone_answered? && RevealAnswer.call(quiz_session: quiz_session)[:success]
        quiz_session.broadcast_host_view
        quiz_session.broadcast_to_players
      else
        quiz_session.broadcast_answer_count(new_participant: @quiz_participant)
      end
      redirect_to quiz_participant_path(@quiz_participant)
    end
  end

  private

  def set_participant
    @quiz_participant = QuizParticipant.find(params[:id])
    unless @quiz_participant.valid_token?(remembered_token(:player_tokens, @quiz_participant.id))
      redirect_to root_path, alert: "Not authorized"
    end
  end
end
