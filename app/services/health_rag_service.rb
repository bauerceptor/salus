class HealthRagService
  DEFAULT_LIMIT = 5

  attr_reader :account, :specialist

  def initialize(account:, specialist: nil)
    @account = account
    @specialist = specialist
  end

  def retrieve_patient_context(query)
    return nil unless patient_rag_enabled?

    embeddings = HealthEmbedding
                 .where(account: account)
                 .validated
                 .by_type(HealthEmbedding::EMBEDDING_TYPES[:patient_message])
                 .order(Arel.sql("embedding <=> '#{query_vector_for(query)}'::vector"))
                 .limit(DEFAULT_LIMIT)

    embeddings.map(&:content).join("\n---\n")
  end

  def retrieve_anonymized_patterns(query)
    return nil unless pattern_rag_enabled?

    HealthEmbedding
      .where(embedding_type: HealthEmbedding::EMBEDDING_TYPES[:anonymized_pattern])
      .validated
      .order(Arel.sql("embedding <=> '#{query_vector_for(query)}'::vector"))
      .limit(DEFAULT_LIMIT)
  end

  def patient_rag_enabled?
    admin_setting(:patient_rag_enabled, default: true)
  end

  def pattern_rag_enabled?
    admin_setting(:pattern_rag_enabled, default: true)
  end

  private

  def admin_setting(key, default:)
    if Rails.configuration.respond_to?(:health_agent) && Rails.configuration.health_agent
      Rails.configuration.health_agent[key] || default
    else
      default
    end
  end

  def query_vector_for(query)
    embedding = RubyLLM.embed(query)
    "[#{embedding.vectors.join(',')}]"
  end
end
