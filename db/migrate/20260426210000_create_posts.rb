class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts, id: :uuid do |t|
      t.string :body, default: "", null: false
      t.integer :post_type, default: 0, null: false
      t.jsonb :metadata, default: {}
      t.references :account, null: false, foreign_key: true, type: :uuid
      t.references :group, null: false, foreign_key: true, type: :uuid
      t.references :quoted_post, null: true, foreign_key: { to_table: :posts }, type: :uuid

      t.timestamps
    end

    add_index :posts, :post_type
    add_index :posts, :quoted_post_id
  end
end
