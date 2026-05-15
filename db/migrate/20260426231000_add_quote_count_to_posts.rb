class AddQuoteCountToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :quote_count, :integer, default: 0
    add_index :posts, :quote_count
  end
end
