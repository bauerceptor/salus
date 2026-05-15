class AddPollVotesCountToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :poll_votes_count, :integer, default: 0
    add_index :posts, :poll_votes_count
  end
end
