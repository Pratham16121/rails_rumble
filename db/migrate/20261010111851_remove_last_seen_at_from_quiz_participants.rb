class RemoveLastSeenAtFromQuizParticipants < ActiveRecord::Migration[8.0]
  def change
    remove_column :quiz_participants, :last_seen_at, :datetime
  end
end
