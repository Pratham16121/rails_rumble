class CreateQuizParticipants < ActiveRecord::Migration[8.0]
  def change
    create_table :quiz_participants do |t|
      t.references :quiz_session, null: false, foreign_key: true
      t.string :nickname, null: false, limit: 30
      t.string :session_token_digest, null: false
      t.integer :status, null: false, default: 0
      t.integer :total_score, null: false, default: 0
      t.datetime :joined_at, null: false
      t.datetime :last_seen_at

      t.timestamps
    end
    add_index :quiz_participants, [ :quiz_session_id, :joined_at ]
  end
end
