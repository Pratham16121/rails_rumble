class AddResponseTimeMsToPlayerAnswers < ActiveRecord::Migration[8.0]
  def change
    add_column :player_answers, :response_time_ms, :integer
  end
end
