class AddExpertPinnedAtToComments < ActiveRecord::Migration[8.1]
  def change
    add_column :comments, :expert_pinned_at, :datetime
    add_index :comments, :expert_pinned_at
  end
end
