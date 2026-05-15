class CreateGroupPosts < ActiveRecord::Migration[8.1]
  def change
    create_table :group_posts, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :group, null: false, type: :uuid
      t.references :account, null: false, type: :uuid
      t.string :title, limit: 255
      t.text :body
      t.timestamps
    end
  end
end
