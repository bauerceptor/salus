class AddBookmarkCountToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :bookmark_count, :integer, default: 0
    add_index :posts, :bookmark_count
  end
end
