class CreateArticleTags < ActiveRecord::Migration[8.1]
  def change
    create_table :article_tags, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :name, null: false, default: ""
      t.timestamps
    end
  end
end
