class QuizParticipantsController < ApplicationController
  before_action :set_participant, only: [:show, :submit_answer]

  def new
    @quiz_participant = QuizParticipant.new
    @join_code = params[:join_code]
  end

  def create
    result = JoinQuizSession.call(
      join_code: params[:quiz_participant][:join_code],
      nickname: params[:quiz_participant][:nickname]
    )

    if result[:error]
      redirect_to new_quiz_participant_path(join_code: params[:quiz_participant][:join_code]), alert: result[:error]
    else
      session[:player_token] = result[:player_token]
      session[:quiz_participant_id] = result[:quiz_participant].id
      
      # Broadcast to host
      ActionCable.server.broadcast(
        "quiz_session_#{result[:quiz_session].id}_host", 
        "<turbo-stream action=\"append\" target=\"participant-list\"><template><li id=\"participant-#{result[:quiz_participant].id}\">#{ERB::Util.html_escape(result[:quiz_participant].nickname)}</li></template></turbo-stream>"
      )
      ActionCable.server.broadcast(
        "quiz_session_#{result[:quiz_session].id}_host", 
        "<turbo-stream action=\"update\" target=\"participant-count\"><template>#{result[:quiz_session].quiz_participants.count}</template></turbo-stream>"
      )

      redirect_to quiz_participant_path(result[:quiz_participant])
    end
  end

  def show
    @quiz_session = @quiz_participant.quiz_session
    # Player's view of the game
  end

  def submit_answer
    result = SubmitAnswer.call(
      quiz_participant: @quiz_participant,
      player_token: session[:player_token],
      question_option_id: params[:question_option_id]
    )

    if result[:error]
      redirect_to quiz_participant_path(@quiz_participant), alert: result[:error]
    else
      redirect_to quiz_participant_path(@quiz_participant), notice: 'Answer submitted!'
    end
  end

  private

  def set_participant
    @quiz_participant = QuizParticipant.find(params[:id])
    unless session[:player_token] && Digest::SHA256.hexdigest(session[:player_token]) == @quiz_participant.session_token_digest
      redirect_to root_path, alert: 'Not authorized'
    end
  end
end
