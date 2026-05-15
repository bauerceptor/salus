class CreateArticleTagAssociations < ActiveRecord::Migration[8.1]
  def change
    create_table :article_tags_articles, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :article, null: false, type: :uuid
      t.references :article_tag, null: false, type: :uuid
      t.timestamps
    end
    add_index :article_tags_articles, %i[article_id article_tag_id], unique: true
  end
end
