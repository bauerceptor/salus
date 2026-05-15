FactoryBot.define do
  factory :health_embedding do
    association :account
    sequence(:content) { |n| "Embedding content #{n}" }
    sequence(:embedding_type) { |n| %w[patient_message specialist_response anonymized_pattern adherence_event][n % 4] }
    metadata { {} }
    validated { false }
    confidence_score { 0 }

    transient do
      embedding_array { nil }
    end

    after(:create) do |record, evaluator|
      if evaluator.embedding_array
        vector_literal = "'[#{evaluator.embedding_array.join(',')}]'::vector"
        record.class.connection.execute(
          "UPDATE health_embeddings SET embedding = #{vector_literal} WHERE id = '#{record.id}'"
        )
      end
    end
  end
end
