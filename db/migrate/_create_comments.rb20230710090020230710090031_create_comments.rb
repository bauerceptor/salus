class CreateComments < ActiveRecord::Migration[8.1]
  def change
    create_table :comments, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :commentable, polymorphic: true, type: :uuid
      t.references :account, null: false, type: :uuid
      t.text :body, null: false
      t.timestamps
    end
    add_index :comments, %i[commentable_type commentable_id]
  end
end
