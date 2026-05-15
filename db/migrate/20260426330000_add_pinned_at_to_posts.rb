class AddPinnedAtToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :pinned_at, :datetime
    add_index :posts, :pinned_at
  end
end
