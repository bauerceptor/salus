class CreateArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :articles, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :account, null: false, type: :uuid
      t.string :title, limit: 255
      t.text :body
      t.string :status, limit: 50, default: "draft"
      t.timestamps
    end
  end
end
