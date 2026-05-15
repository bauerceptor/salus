class CreateHashtags < ActiveRecord::Migration[8.1]
  def change
    create_table :hashtags, id: :uuid do |t|
      t.string :name, null: false
      t.integer :post_count, default: 0
      t.integer :trending_score, default: 0

      t.timestamps
    end

    add_index :hashtags, :name, unique: true
    add_index :hashtags, :trending_score

    create_table :post_hashtags, id: :uuid do |t|
      t.references :post, null: false, foreign_key: true, type: :uuid
      t.references :hashtag, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_index :post_hashtags, %i[post_id hashtag_id], unique: true
  end
end
