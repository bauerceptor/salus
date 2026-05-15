# AI Health Agents in Rails - Research Findings

## 1. RubyLLM Integration Patterns (Chat with Attachments)

**Note**: RubyLLM doesn't appear to be a widely documented gem. The primary Ruby library for LLM integration is the OpenAI Ruby SDK directly, or ankane's library collection.

### Recommended Pattern for Rails + OpenAI + Attachments

```ruby
# Use OpenAI Ruby SDK directly for chat with image attachments
require "openai"

client = OpenAI::Client.new

response = client.chat_with attachments do |t|
  t.messages do |m|
    m.role("user") do |content|
      content.content([
        { type: "text", text: "What's in this image?" },
        { type: "image_url", image_url: { url: "data:image/jpeg;base64,..." } }
      ])
    end
  end
end
```

**For PDFs**: Use libraries like `pdf-reader` to extract text, then send as text content.

### Alternative: Use Langchain.rb
Consider [Langchain.rb](https://github.com/rootstrap/langchain) for more advanced agent patterns including tool use, RAG, and multi-step reasoning.

---

## 2. RAG with pgvector in Rails

### Key Libraries
- **[pgvector](https://github.com/pgvector/pgvector)** - Open-source vector similarity search for Postgres
- **[Neighbor](https://github.com/ankane/neighbor)** - Nearest neighbor search for Rails (wraps pgvector)

### Implementation Pattern

```ruby
# Migration
class AddEmbeddingToDocuments < ActiveRecord::Migration[8.1]
  def change
    add_column :documents, :embedding, :vector, limit: 1536  # OpenAI ada-002 dimensions
    add_index :documents, :embedding, using: :hnsw, opclass: :vector_cosine_ops
  end
end

# Model
class Document < ApplicationRecord
  has_neighbors :embedding
end

# Generate embedding via OpenAI
def embed(input)
  client = OpenAI::Client.new
  response = client.embeddings.create(
    parameters: {
      input: input,
      model: "text-embedding-3-small"  # 1536 dimensions
    }
  )
  response.dig("data", 0, "embedding")
end

# RAG Query Flow
def retrieve_context(query, top_k: 5)
  query_embedding = embed(query)
  Document.nearest_neighbors(:embedding, query_embedding, distance: "cosine").first(top_k)
end

def answer_with_rag(question)
  context = retrieve_context(question)
  prompt = "Context: #{context.map(&:content).join("\n")}\n\nQuestion: #{question}"
  
  client = OpenAI::Client.new
  client.chat_with attachments do |t|
    t.messages do |m|
      m.role("system", content: "You are a helpful medical assistant. Use the provided context.")
      m.role("user", content: prompt)
    end
  end
end
```

### Index Types
- **HNSW**: Better query performance, slower builds, more memory (recommended for production)
- **IVFFlat**: Faster builds, less memory, lower recall - good for larger datasets

### Hybrid Search Pattern
```ruby
class Document < ApplicationRecord
  has_neighbors :embedding

  scope :keyword_search, ->(query) {
    where("to_tsvector(content) @@ plainto_tsquery(?)", query)
  }
end

# Combine vector + keyword search with RRF (Reciprocal Rank Fusion)
```

---

## 3. Health Agent Patterns (Observe, Learn, Notify)

Based on research from Deloitte, Nature, and industry sources.

### Agent Architecture Pattern

```ruby
class HealthAgent
  def initialize(patient)
    @patient = patient
    @observation_buffer = []
  end

  def observe(data_point)
    @observation_buffer << {
      timestamp: Time.current,
      data: data_point,
      metadata: extract_metadata(data_point)
    }
    trigger_learning if observation_threshold_reached?
  end

  def learn
    # Analyze patterns in observation buffer
    # Update patient risk scores, generate insights
    # Store learned patterns in pgvector for future retrieval
    patterns = analyze_patterns(@observation_buffer)
    update_patient_model(patterns)
  end

  def notify_doctor
    # Escalation logic based on learned patterns
    # Generate structured notification with urgency level
    # Create follow-up task in system
  end
end
```

### Key Patterns from Industry
1. **Continuous Monitoring**: Agents observe patient data streams (vitals, symptoms, adherence)
2. **Pattern Recognition**: ML models identify concerning trends before they become critical
3. **Escalation Framework**: Tiered notifications (info → advisory → urgent → critical)
4. **Feedback Loop**: Doctor responses train the agent's future recommendations

**Source**: [Deloitte - Health care leans into agentic AI](https://www.deloitte.com/us/en/insights/industry/health-care/agentic-ai-health-care-operating-model-change.html)

---

## 4. Patient-Specialist Dual Interface Design

### Design Principles

**Patient Interface (Front-end)**
- Conversational AI for symptom description and triage
- Attachment support for images (skin conditions, injuries) and PDFs (lab results)
- Simple symptom checker with clear next-step guidance
- Privacy-first design with explicit consent flows

**Specialist Interface (Back-office)**
- AI-summarized patient history and key observations
- Quick access to relevant medical literature via RAG
- Decision support: "Based on similar cases, recommended action is..."
- Override capability: specialist can adjust AI recommendations

### Pattern: Context Separation

```ruby
class MedicalChatbotController < ApplicationController
  def patient_message
    # Patient sees: conversational UI, non-technical language
    # AI responds within scope: triage, general info, appointment scheduling
    # Anything serious → flag for specialist review
  end

  def specialist_view
    # Specialist sees: full conversation, AI analysis, patient history
    # Can intervene, adjust recommendations, schedule follow-ups
  end
end
```

### Key UX Patterns
- **Transparency**: Patient knows they're talking to an AI
- **Escalation paths**: Clear when conversation moves to human specialist
- **Documentation**: All AI recommendations logged for specialist review

---

## 5. Guardrails for Medical AI Agents

### Scope Limiting Patterns

```ruby
class MedicalGuardrails
  SCOPE_TOPICS = %w[
    symptoms medication_adherence appointment_scheduling
    general_health_info triage basic_first_aid
  ].freeze

  OFF_TOPICS = %w[
    diagnosis prescription specific_treatment_plan
    emergency guidance mental_health_counseling
  ].freeze

  def within_scope?(message)
    # Check if message topic is in allowed scope
    topic = classify_topic(message)
    SCOPE_TOPICS.include?(topic)
  end

  def handle_off_topic(message)
    # Redirect to appropriate resource
    # Offer to connect with specialist
    # Never provide specific medical advice outside scope
  end

  def classify_topic(message)
    # Use LLM or keyword matching to classify
  end
end
```

### Guardrail Implementation

```ruby
class MedicalChatService
  def initialize
    @guardrails = MedicalGuardrails.new
    @rag_system = MedicalRAGSystem.new
  end

  def respond(message, patient_context)
    if @guardrails.emergency_detected?(message)
      return emergency_response
    end

    unless @guardrails.within_scope?(message)
      return @guardrails.handle_off_topic(message)
    end

    # Process within scope
    context = @rag_system.retrieve_relevant(patient_context, message)
    generate_response(message, context, patient_context)
  end

  def emergency_response
    {
      message: "I notice you may be describing an emergency. Please call 911 or your local emergency services immediately.",
      type: "emergency_escalation",
      recommended_action: "contact_emergency_services"
    }
  end
end
```

### Key Guardrail Types
1. **Topic Scope**: Stick to general health, triage, scheduling; avoid diagnosis/treatment
2. **Emergency Detection**: Recognize crisis language → immediate human escalation
3. **Uncertainty Expression**: AI should say "I'm not certain, let me connect you with a specialist"
4. **Source Attribution**: Ground responses in retrieved medical literature
5. **Disclaimer Layer**: "This is general information, not a medical diagnosis"

---

## 6. Medical Chatbot Design Principles

### Foundational Principles

1. **Safety First**
   - Never bypass guardrails for "better UX"
   - Emergency detection is non-negotiable
   - Clear scope boundaries

2. **Transparency**
   - Patients know they're talking to AI
   - AI explains its reasoning when providing general info
   - Clear when human specialist is needed

3. **Accuracy & Attribution**
   - RAG grounding ensures responses tied to verified sources
   - Regular updates to medical knowledge base
   - Confidence scoring on responses

4. **Privacy & Compliance**
   - HIPAA considerations for all data handling
   - Consent flows before medical discussions
   - Data minimization principles

### Response Templates

```ruby
class MedicalResponseBuilder
  def build_response(type:, content:, confidence:, sources:, next_steps:)
    {
      message: content,
      metadata: {
        type: type,
        confidence: confidence,
        sources: sources,
        ai_powered: true,
        disclaimer: "This is general health information, not a medical diagnosis. Consult a healthcare professional for personalized advice.",
        next_steps: next_steps
      }
    }
  end
end
```

### Anti-Patterns to Avoid
- **Diagnosis without verification**: AI should never state "you have X"
- **Treatment plans**: Stick to general guidance, not specific prescriptions
- **Absolute language**: Use "may" "could" "recommend consulting" instead of "will" "must"
- **Overconfidence in edge cases**: Flag complex cases for specialists

---

## Summary: Key Libraries & Patterns

| Component | Recommended Library | Notes |
|-----------|---------------------|-------|
| LLM Integration | `openai` Ruby SDK | Direct API access |
| Vector Search | `neighbor` + `pgvector` | ankane's Rails integration |
| RAG Implementation | Custom with Neighbor | See hybrid search pattern |
| Agent Framework | `langchain.rb` | For complex multi-step agents |
| PDF Processing | `pdf-reader` | Extract text for embeddings |

## Architecture Recommendations

```
┌─────────────────────────────────────────────────────────────┐
│                        Rails App                            │
├─────────────────────────────────────────────────────────────┤
│  Controllers          Services              Models           │
│  ├── ChatController  ├── MedicalChatService  ├── Document   │
│  ├── AgentController ├── RAGSystem           ├── Patient     │
│  └── AdminController ├── GuardrailsService   └── MedicalRecord
├─────────────────────────────────────────────────────────────┤
│  External APIs                                              │
│  ├── OpenAI (chat + embeddings)                             │
│  └── Pgvector (vector storage/search)                      │
└─────────────────────────────────────────────────────────────┘
```

## Key Sources

- [pgvector GitHub](https://github.com/pgvector/pgvector)
- [Neighbor - Nearest neighbor search for Rails](https://github.com/ankane/neighbor)
- [Nature - AI agent in healthcare](https://www.nature.com/articles/s44387-026-00076-4)
- [Deloitte - Agentic AI in Health Care](https://www.deloitte.com/us/en/insights/industry/health-care/agentic-ai-health-care-operating-model-change.html)
- [Observe.AI - Healthcare AI Agents](https://www.observe.ai/industry/healthcare-ai-agents)
- [Paxrel - AI Agent for Healthcare](https://paxrel.com/blog-ai-agent-healthcare)