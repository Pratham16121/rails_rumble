class AddStreakToPlayerAnswers < ActiveRecord::Migration[8.0]
  def change
    add_column :player_answers, :streak, :integer, default: 0, null: false
  end
end
