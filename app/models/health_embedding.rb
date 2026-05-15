class HealthEmbedding < ApplicationRecord
  belongs_to :account

  EMBEDDING_TYPES = {
    patient_message: "patient_message",
    specialist_response: "specialist_response",
    anonymized_pattern: "anonymized_pattern",
    adherence_event: "adherence_event"
  }.freeze

  scope :validated, -> { where(validated: true) }
  scope :by_type, ->(type) { where(embedding_type: type) }

  def self.embed_and_store(content:, embedding_type:, account:, metadata: {})
    result = RubyLLM.embed(content)
    vector = result.vectors

    vector_literal = "'[#{vector.join(',')}]'::vector"

    connection.execute <<~SQL.squish
      INSERT INTO health_embeddings
        (id, account_id, content, embedding_type, embedding, metadata, confidence_score, validated, created_at, updated_at)
      VALUES
        (gen_random_uuid(), #{connection.quote(account.id)}, #{connection.quote(content)}, #{connection.quote(embedding_type)}, #{vector_literal}, #{connection.quote(metadata.to_json)}, 0, false, NOW(), NOW())
    SQL

    where(account: account, content: content).last
  end

  def self.similarity_search(query:, account:, embedding_type: nil, limit: 5)
    query_embedding = RubyLLM.embed(query)
    query_vector = query_embedding.vectors

    scope = where(account: account).validated
    scope = scope.where(embedding_type: embedding_type) if embedding_type

    vector_literal = "'[#{query_vector.join(',')}]'::vector"
    scope
      .order(Arel.sql("embedding <=> #{vector_literal}"))
      .limit(limit)
  end
end
