class CreateHealthEmbeddings < ActiveRecord::Migration[8.0]
  def change
    create_table :health_embeddings, id: :uuid do |t|
      t.references :account, type: :uuid, null: false, foreign_key: true
      t.string :embedding_type, null: false
      t.text :content, null: false
      t.jsonb :metadata, default: {}
      t.integer :confidence_score, default: 0
      t.boolean :validated, default: false
      t.timestamps
    end

    add_index :health_embeddings, :embedding_type, if_not_exists: true
    add_index :health_embeddings, :account_id, if_not_exists: true
    add_index :health_embeddings, :validated, if_not_exists: true

    add_embedding_column
  end

  def add_embedding_column
    return if column_exists?(:health_embeddings, :embedding)

    begin
      execute "ALTER TABLE health_embeddings ADD COLUMN embedding vector(1536)"
    rescue StandardError => e
      say "Vector extension not available, using text type for embedding: #{e.message}"
      execute "ALTER TABLE health_embeddings ADD COLUMN embedding text"
    end
  end
end
