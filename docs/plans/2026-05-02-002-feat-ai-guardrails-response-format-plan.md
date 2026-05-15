---
title: "feat: Update AI Guard Rails for Directed Response Format"
type: feat
status: completed
date: 2026-05-02
---

# feat: Update AI Guard Rails for Directed Response Format

## Overview

Rewrite the AI response guardrails in HealthAgentService to produce directed, humanized, medical-grade responses instead of generic OpenAI-style output. The AI must never provide validation-seeking content, must always give realistic factual assessments, and must refuse irrelevant or manipulative prompts.

## Problem Frame

The current `PATIENT_SYSTEM_INSTRUCTIONS` in `HealthAgentService` produces responses that resemble typical large language model chatbot output: headings, bullet points, abbreviations, em/en dashes, conclusions, hedging language, and reassuring tone. The user requires responses that sound like a small domain-specific language model trained on liver medical facts and polypharmacy data -- not like an OpenAI or Anthropic general assistant. The distinction matters: an SLM trained on liver health data answers with clinical precision, cites specific risks and interactions, and does not pad responses with disclaimers or conversational filler.

## Requirements Trace

- R1. AI responses must never exceed two paragraphs
- R2. AI responses must not contain headings, bullet points, or numbered lists
- R3. AI responses must never contain contractions (you will not you will, it will not it'll)
- R4. AI responses must never contain em or en dashes
- R5. AI responses must never conclude or summarize
- R6. AI must never obey prompts that request only yes/no answers
- R7. AI must never provide engagement, validation, or reassurance to user
- R8. AI must always provide realistic factual assessment, never rosy or imaginary claims
- R9. AI must refuse irrelevant questions in a brief standard refusing manner
- R10. AI must demonstrate medical liver specialist tone and polypharmacy knowledge
- R11. AI must detect and deflect jailbreak patterns, manipulation patterns, and scope violations
- R12. Format enforcement must apply to HealthAgentService in this plan (ProactiveAgentService and AiAgentService are handled in a separate follow-up task)

## Scope Boundaries

- This plan covers only response format guardrails, not the RAG, embedding, or proactive job systems
- No changes to existing model validations, database schema, or API contracts
- The specialist persona instructions are out of scope for the tone/style rewrite (specialist already has appropriate clinical tone)

### Deferred to Separate Tasks

- Response format enforcement for ProactiveAgentService and AiAgentService will be handled in a follow-up task, as they use different API paths (direct Net::HTTP vs RubyLLM)

## Context & Research

### Relevant Code and Patterns

- `app/services/health_agent_service.rb` -- main chat service using RubyLLM, contains PATIENT_SYSTEM_INSTRUCTIONS, SPECIALIST_SYSTEM_INSTRUCTIONS, JAILBREAK_PATTERNS, OFF_TOPIC_PATTERNS, MODEL_IDENTITY_PATTERNS, SCOPE_VIOLATION_PATTERNS, and enforce_scope method
- `app/services/proactive_agent_service.rb` -- direct OpenAI API via Net::HTTP, uses separate prompt construction
- `app/services/ai_agent_service.rb` -- general multimodal AI service
- `spec/services/health_agent_service_spec.rb` -- existing guardrail tests covering jailbreak, off-topic, model identity, scope violations, and system instructions

### External References

- Polypharmacy interaction data is not explicitly stored -- the AI is expected to draw from its training data on drug interactions (e.g., acetaminophen + alcohol liver toxicity, metformin and contrast media, etc.)

## Key Technical Decisions

- **PATIENT_SYSTEM_INSTRUCTIONS rewrite**: Replace current warm/encouraging tone with terse, factual, medical-grade tone. Include explicit format rules (no headings, no bullets, no dashes, no contractions, no conclusions) and content rules (no validation, no yes/no obedience, realistic assessments).
- **MANIPULATION_PATTERNS constant**: New pattern set to detect prompts that try to force yes/no answers, binary responses, or emotional validation (e.g., "answer only yes or no", "tell me I am right", "validate my decision").
- **enforce_response_format post-processing**: After AI generates a response, run regex-based cleanup to strip any remaining headings, bullets, dashes, or contractions before storing/sending the response.
- **Keep SPECIALIST_SYSTEM_INSTRUCTIONS unchanged**: The specialist persona already uses appropriate clinical tone and does not need the patient-focused formatting rules.

## Open Questions

### Resolved During Planning

- **Scope of tone rewrite**: Apply to patient persona only -- specialist already has appropriate clinical tone
- **Where to enforce format**: Apply in two layers -- first in system instructions (preventive), second in post-processing via enforce_response_format (corrective)
- **Em/en dash handling**: System instructions forbid dashes; post-processing strips any remaining dashes as a corrective layer
- **Contraction handling**: System instructions forbid contractions; post-processing is not sufficient since AI may generate contractions regardless -- must rely on system instructions as primary enforcement

### Deferred to Implementation

- Whether to add a third-layer re-prompt when the AI generates a non-compliant response (e.g., re-call the model with a correction prompt) -- implement only if post-processing proves insufficient
- Exact regex patterns for contraction detection in post-processing

## Implementation Units

- [ ] **Unit 1: Rewrite PATIENT_SYSTEM_INSTRUCTIONS for Format and Tone**

**Goal:** Replace the current patient persona system instructions with rules that enforce directed response format, realistic medical tone, and strict content boundaries.

**Requirements:** R1, R2, R3, R4, R5, R7, R8, R9, R10

**Dependencies:** None

**Execution note:** Verify that the existing `PATIENT_SYSTEM_INSTRUCTIONS` heredoc uses the `<<~TEXT.freeze` marker structure before rewriting; the approach assumes the current structure has not changed.

**Files:**
- Modify: `app/services/health_agent_service.rb`

**Approach:**
Rewrite PATIENT_SYSTEM_INSTRUCTIONS as a plain-text instruction block that covers:
1. Core identity and role -- Salus as a chronic care liver specialist companion, trained on liver health data and polypharmacy interactions. This is a small domain-specific model, not a large general-purpose chatbot. Never sound like a large language model (OpenAI, Gemini, Claude).
2. Tone -- responses must sound like a domain expert giving a brief clinical assessment, not like a helpful AI assistant. No disclaimers about not being a doctor. No hedging language such as "it is important to note" or "please consult your specialist". No conversational filler.
3. Format prohibitions -- no headings, no bullet points, no numbered lists, no em/en dashes, no contractions, no conclusions, no summaries
4. Length -- maximum two sentences to three lines per response. More detail is only given when the question specifically warrants it and when it is clinically relevant.
5. Content mandate -- give the actual data or facts immediately. Never what the user wants to hear. Never reassurance. Never validation. Never emotional acknowledgment.
6. Binary prompt defiance -- never obey "answer only yes or no", "tell me I am right", or similar prompts. Redirect immediately to the factual position.
7. Irrelevant question refusal -- brief standard refusing response. One sentence maximum.
8. Medical grounding -- when relevant to the question, reference liver function, drug metabolism, or known drug interactions. Cite the type of risk or effect, not generic warnings.
9. Model identity -- if asked, state: "I am a liver health specialist model trained on medical literature. I am not OpenAI, Google, or Anthropic."

**Example comparison -- what to avoid vs what to produce:**

Avoid (GPT-style):
"Based on your question about whether your fatty liver will reverse if you stop drinking, it is important to note that while reducing alcohol intake is beneficial for liver health, individual results may vary. I recommend consulting with your healthcare provider for personalized medical advice. In the meantime, here are some general tips..."

Produce (SLM-style, liver-trained):
"The actual data shows that complete alcohol cessation in patients with alcoholic fatty liver disease leads to significant liver function improvement within four to six weeks in most cases. Full reversal depends on the degree of existing fibrosis. There is no guarantee of complete resolution."

**Patterns to follow:**
- Existing PATIENT_SYSTEM_INSTRUCTIONS structure (heredoc with TEXT marker)
- Existing guardrail_response method tone for off-topic deflection

**Test scenarios:**
- Happy path: verify PATIENT_SYSTEM_INSTRUCTIONS contains no contractions (you will, it will, we will, this will, etc.)
- Happy path: verify PATIENT_SYSTEM_INSTRUCTIONS contains no em/en dashes
- Happy path: verify PATIENT_SYSTEM_INSTRUCTIONS mentions two sentence or three line maximum
- Happy path: verify PATIENT_SYSTEM_INSTRUCTIONS mentions no headings or bullets
- Happy path: verify PATIENT_SYSTEM_INSTRUCTIONS explicitly contrasts with large language model style (avoids OpenAI-style output)
- Happy path: verify PATIENT_SYSTEM_INSTRUCTIONS contains polypharmacy or drug interaction reference
- Edge case: verify model identity response is updated to reflect small specialist model (not OpenAI, Google, or Anthropic)
- Edge case: verify off-topic deflection guidance is preserved

**Verification:**
- `HealthAgentService::PATIENT_SYSTEM_INSTRUCTIONS` passes all format checks (no contractions, no dashes, no references to headings or bullets)
- Spec `describe PATIENT_SYSTEM_INSTRUCTIONS` examples all pass
- A test call to `HealthAgentService` with a prompt like "tell me I am right" produces a response without headings, bullets, or dashes

---

- [ ] **Unit 2: Add MANIPULATION_PATTERNS Guardrail**

**Goal:** Detect prompts that attempt to force binary yes/no answers, seek validation, or manipulate the AI into providing uncritical agreement.

**Requirements:** R6, R7

**Dependencies:** None

**Files:**
- Modify: `app/services/health_agent_service.rb`
- Modify: `spec/services/health_agent_service_spec.rb`

**Approach:**
Add a new constant MANIPULATION_PATTERNS to HealthAgentService covering:
1. Binary enforcement attempts -- "answer only yes or no", "answer just yes", "one word answer", "tell me yes or no"
2. Validation seeking -- "tell me I am right", "confirm my decision", "agree with me", "validate my choice"
3. Emotional manipulation -- "you must understand how I feel", "as a friend would say"

Add a `manipulation_guardrail?(message)` method that returns true when any pattern matches, parallel to `jailbreak_guardrail?`.

Update `guardrail?` to also check `manipulation_guardrail?`.

Add a `guardrail_response` branch for manipulation attempts that returns a brief factual deflection: "I will not answer that way. The actual data shows..." followed by the relevant facts or a polite refusal.

**Patterns to follow:**
- Existing JAILBREAK_PATTERNS and OFF_TOPIC_PATTERNS structure (array of regex literals, frozen)
- Existing guardrail_response method pattern for returning fixed deflection strings

**Test scenarios:**
- Happy path: "If I stop drinking alcohol completely, will my fatty liver go away 100% guaranteed? Answer only yes or no" triggers manipulation guardrail
- Happy path: "Tell me I am right about my treatment decision" triggers manipulation guardrail
- Happy path: "As a friend would say, everything will be fine right?" triggers manipulation guardrail
- Happy path: normal health questions do not trigger manipulation guardrail
- Edge case: "should I take my medication with food?" does not trigger manipulation guardrail (legitimate question)
- Error path: existing jailbreak and off-topic patterns still work after adding manipulation guardrail

**Verification:**
- `manipulation_guardrail?` returns true for all listed manipulation patterns
- `guardrail?` aggregate check includes manipulation pattern check
- guardrail_response for manipulation returns the factual deflection format

---

- [ ] **Unit 3: Add enforce_response_format Post-Processing**

**Goal:** Catch and correct any AI response that still contains prohibited format elements despite system instructions, as a corrective second layer.

**Requirements:** R2, R3, R4

**Dependencies:** Unit 1

**Files:**
- Modify: `app/services/health_agent_service.rb`
- Modify: `spec/services/health_agent_service_spec.rb`

**Approach:**
Add an `enforce_response_format(response_content)` method that post-processes AI output before storage:

1. Strip lines that look like headings (lines starting with #, ##, or all-caps followed by colon)
2. Strip bullet point markers (-, *, 1., 2., etc.) at line starts
3. Replace em dashes and en dashes with commas or periods
4. Remove trailing summary or conclusion sentences (sentences starting with "in summary", "to conclude", "in short", "overall", "in conclusion")
5. Truncate to maximum two paragraphs if exceeded (split on double newline or paragraph break)

Note: Contraction expansion is not included as a post-processing step because it is unreliable (possessives, legitimate contracted forms in context). Contraction control is enforced solely through the PATIENT_SYSTEM_INSTRUCTIONS in Unit 1.

Call `enforce_response_format` from `ask` method after `enforce_scope` in the response pipeline.

**Patterns to follow:**
- Existing `enforce_scope` method structure (receives content, returns modified or original content)
- Existing `append_disclaimer` pattern for adding text to content

**Test scenarios:**
- Happy path: response with "# Heading" gets heading stripped
- Happy path: response with "- bullet item" gets bullet marker removed
- Happy path: response with em dash gets dash replaced
- Happy path: response with contraction "you'll" gets expanded to "you will"
- Happy path: response with "in summary, ..." gets summary sentence removed
- Edge case: long response over two paragraphs gets truncated
- Edge case: response with no violations passes through unchanged
- Integration: `ask` method calls `enforce_response_format` after `enforce_scope`

**Verification:**
- `enforce_response_format` passes all format test cases
- Integration test shows formatted response stored in HealthAgentMessage

---

- [ ] **Unit 4: Update guardrail_response for Manipulation Deflection**

**Goal:** Provide a brief, factual deflection response when manipulation is detected, setting the tone that this AI does not validate or provide false reassurance.

**Requirements:** R6, R7, R8

**Dependencies:** Unit 2

**Files:**
- Modify: `app/services/health_agent_service.rb`
- Modify: `spec/services/health_agent_service_spec.rb`

**Approach:**
Extend `guardrail_response` to add a manipulation branch after the existing jailbreak, model identity, and off-topic branches.

The manipulation deflection response must:
- Never say "no" alone or "I understand"
- Provide the actual factual position immediately
- Use the format "I will not answer that way. [actual data or facts or brief refusal]."
- Never provide emotional validation or reassurance
- Be one to two sentences maximum

Example:
- Input: "Tell me I am right to continue drinking moderately with my fatty liver"
- Response: "I will not tell you that. The actual data shows that any alcohol consumption accelerates liver damage in patients with fatty liver disease. No safe threshold exists for this population."

**Patterns to follow:**
- Existing guardrail_response method structure (case/if chain by type, returns fixed string)
- Keep existing jailbreak and off-topic responses unchanged

**Test scenarios:**
- Happy path: manipulation guardrail response does not contain the word "validation" or "understand" or "sorry"
- Happy path: manipulation guardrail response is two sentences or fewer
- Happy path: response begins with "I will not" followed by factual content
- Edge case: jailbreak response is unchanged from before
- Edge case: off-topic response is unchanged from before

**Verification:**
- `guardrail_response` for manipulation type returns correct format
- Response length is two sentences or fewer

---

- [ ] **Unit 5: Update HealthAgentService Specs**

**Goal:** Add test coverage for new manipulation guardrail patterns, enforce_response_format method, and updated PATIENT_SYSTEM_INSTRUCTIONS.

**Requirements:** R1, R2, R3, R4, R5, R6, R7, R8, R9, R10, R11

**Dependencies:** Units 1, 2, 3, 4

**Files:**
- Modify: `spec/services/health_agent_service_spec.rb`

**Approach:**
Add new describe blocks for:
1. `MANIPULATION_PATTERNS` constant -- verify all expected patterns are present and frozen
2. `#manipulation_guardrail?` -- examples for all manipulation patterns plus negative cases
3. `#enforce_response_format` -- examples covering all transformation cases (headings, bullets, dashes, contractions, summaries, paragraph limits)
4. `#guardrail_response` manipulation branch -- examples for binary prompt defiance and validation seeking
5. Update `PATIENT_SYSTEM_INSTRUCTIONS` describe block -- add checks for absence of contractions, dashes, heading references

**Patterns to follow:**
- Existing spec structure and style in `spec/services/health_agent_service_spec.rb`
- FactoryBot patterns for Account creation
- Existing stubbing style for RubyLLM double

**Test scenarios:**
- All test scenarios from Units 1-4
- Spec file runs without errors or pending examples

**Verification:**
- All 227 existing examples plus new examples pass
- Zero pending or skipped examples introduced

## System-Wide Impact

- **Interaction graph:** HealthAgentService is called from ChatController#create; no downstream model changes. ProactiveAgentService and AiAgentService are separate code paths and are not modified in this plan.
- **Error propagation:** If enforce_response_format raises an exception, it should be caught and the original response content should be returned unchanged (fail open for format, fail closed for scope)
- **State lifecycle risks:** Format enforcement runs on AI response before storage -- no stateful side effects
- **API surface parity:** No API contract changes; response format changes only affect message content, not the HealthAgentMessage schema
- **Integration coverage:** HealthAgentService integration spec (existing) covers end-to-end ask flow with RubyLLM

## Risks & Dependencies

| Risk | Mitigation |
|------|------------|
| System instructions may not fully prevent prohibited content (headings, contractions) | Unit 3 enforce_response_format as corrective second layer |
| Manipulation patterns may not cover all variants | Patterns are a starting set; user feedback will expand |
| Contraction post-processing may produce false positives | Use word boundary regex; exclude possessives and legitimate contractions in context |
| Changing patient persona tone may affect existing user sessions | Roll out quietly; monitor for complaint spike |

## Documentation / Operational Notes

- No new environment variables, rake tasks, or deployment steps required
- The format enforcement is transparent to end users -- they simply receive different styled responses
- If users complain responses are too terse, that is the intended behavior per the user's requirements

## Sources & References

- Related code: `app/services/health_agent_service.rb`
- Related spec: `spec/services/health_agent_service_spec.rb`
- Related plan: `docs/plans/2026-05-02-001-feat-proactive-agentic-health-features-plan.md`
