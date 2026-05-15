class CreatePostBookmarks < ActiveRecord::Migration[8.1]
  def change
    create_table :post_bookmarks, id: :uuid do |t|
      t.references :account, null: false, foreign_key: true, type: :uuid
      t.references :post, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_index :post_bookmarks, :account_id
    add_index :post_bookmarks, :post_id
    add_index :post_bookmarks, %i[account_id post_id], unique: true
  end
end
