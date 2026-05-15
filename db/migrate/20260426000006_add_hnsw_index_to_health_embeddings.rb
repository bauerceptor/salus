class AddHnswIndexToHealthEmbeddings < ActiveRecord::Migration[8.0]
  def up
    return unless table_exists?(:health_embeddings)
    return unless column_exists?(:health_embeddings, :embedding)

    begin
      execute "CREATE INDEX IF NOT EXISTS index_health_embeddings_on_embedding_hnsw ON health_embeddings USING hnsw (embedding vector_cosine_ops)"
    rescue StandardError => e
      say "Could not create HNSW index (vector type may not be available): #{e.message}"
    end
  end

  def down
    return unless table_exists?(:health_embeddings)

    begin
      execute "DROP INDEX IF EXISTS index_health_embeddings_on_embedding_hnsw"
    rescue StandardError
      nil
    end
  end
end
