# In test environment, ensure the vector column exists with correct type
# since the schema dumper cannot represent custom PostgreSQL vector type
Rails.logger.debug "Setting up health_embeddings vector column for test environment..."

if Rails.env.test?
  begin
    conn = ActiveRecord::Base.connection

    if conn.table_exists?("health_embeddings")
      existing_type = conn.execute("SELECT data_type FROM information_schema.columns WHERE table_name = 'health_embeddings' AND column_name = 'embedding'").first&.[]("data_type")

      if existing_type == "USER-DEFINED"
        Rails.logger.debug "Embedding column already has vector type"
      else
        Rails.logger.debug { "Converting embedding column from #{existing_type} to vector(1536)..." }
        conn.execute("ALTER TABLE health_embeddings ALTER COLUMN embedding TYPE vector(1536) USING embedding::text::vector")
        Rails.logger.debug "Vector column type set successfully"
      end

      begin
        result = conn.execute("SELECT indexname FROM pg_indexes WHERE indexname = 'index_health_embeddings_on_embedding_hnsw'")
        if result.none?
          Rails.logger.debug "Creating HNSW index on embedding column..."
          conn.execute("CREATE INDEX index_health_embeddings_on_embedding_hnsw ON health_embeddings USING hnsw (embedding vector_cosine_ops)")
          Rails.logger.debug "HNSW index created successfully"
        else
          Rails.logger.debug "HNSW index already exists"
        end
      rescue StandardError => e
        Rails.logger.debug { "Note: HNSW index creation skipped - #{e.message}" }
      end
    end
  rescue StandardError => e
    Rails.logger.debug { "Warning: Could not set up vector column - #{e.message}" }
  end
end
