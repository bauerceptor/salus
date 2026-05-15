class CreateReactions < ActiveRecord::Migration[8.1]
  def change
    create_table :reactions, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :account, null: false, type: :uuid
      t.references :reactable, polymorphic: true, type: :uuid
      t.string :reaction_type, limit: 50, null: false
      t.timestamps
    end
    add_index :reactions, %i[account_id reactable_type reactable_id]
  end
end
