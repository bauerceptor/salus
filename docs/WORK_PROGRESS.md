# Salus Work Progress

**Last Updated:** 2026-04-27

## Current Focus
Health Agent Chat - Voice, Text, and Attachments functionality

## TDD Status: Health Agent Attachments

### Completed (TDD Cycle)
1. **Tests Written First** - 11 tests covering:
   - GET #index authenticated/unauthenticated
   - POST #create with text, attachments, voice
   - Empty content validation
   - Specialist persona

2. **Implementation (Green)**
   - Model: Added `has_one_attached :attachment` to HealthAgentMessage
   - Controller: Handle attachment upload, return attachment_url in JSON
   - View: Display attachments in messages (images, audio, documents)
   - JavaScript: File input handling, voice recording with MediaRecorder API

3. **Tests Passing:** 11/11

## Database Migration Status

### Development Database
- [x] All 120 migrations applied
- [x] health_embeddings table created (with text fallback for embedding column)
- [x] Vector extension handled gracefully with fallback

### Test Database
- [x] All migrations applied successfully
- [x] 96 tables created
- [x] health_embeddings table with correct structure

## Analysis: Health Agent Chat Issues

### Fixed Issues

#### 1. Attachments - JavaScript sends files
**Location:** `app/views/health_agent/chat/index.html.erb`
**Fix:** FormData now appends file from photo/document inputs

#### 2. Voice Recording - Implemented
**Location:** `app/views/health_agent/chat/index.html.erb`
**Fix:** MediaRecorder API, start/stop recording, send as audio/mpeg blob

#### 3. Controller - Active Storage attachments
**Location:** `app/controllers/health_agent/chat_controller.rb`
**Fix:** `message.attachment.attach(params[:attachment])`

## Completed Work (Today)

### 1. Rubocop
- [x] `rubocop -a` - corrected 2457 offenses
- [x] `rubocop -A` - corrected 751 more offenses
- [x] `rubocop -a app/` - corrected most app code issues
- [x] Fixed syntax error in `import_factory.rb` (for → self.for)

### 2. Code Quality Fixes
- [x] Removed duplicate `jailbreak_guardrail?` method in HealthAgentService
- [x] Renamed `has_attachment?` → `attachment?` in ChatroomMessage
- [x] Renamed `has_attachments?` → `attachments?` in SpecialistMessage
- [x] Renamed `has_address?` → `address?` in PatientExporter
- [x] Moved `CONFIDENCE_LEVELS` out of private section
- [x] Fixed duplicate branches in ConditionExporter
- [x] Fixed BaseController inheritance in HealthAgent controllers

### 3. Test Infrastructure
- [x] Added `sign_out` helper to `spec/support/auth_helpers.rb`
- [x] Created `spec/requests/health_agent/chat_controller_spec.rb` (11 tests)
- [x] Fixed controller to inherit from `HealthAgent::BaseController`
- [x] Fixed `persona_patient?` enum method name

### 4. Bug Fixes
- [x] `HealthAgent::BaseController` - added missing `user_account_setup` method
- [x] `HealthAgent::ChatController` - added content presence validation
- [x] `MeasurementsController#create` - save result not checked (showed success even when save failed)

### 5. Health Agent Attachments (TDD)
- [x] Model: `has_one_attached :attachment`
- [x] Controller: Handle attachment upload with Active Storage
- [x] View: Display image/audio/document attachments
- [x] JavaScript: File input + voice recording with MediaRecorder
- [x] 11 tests passing

## Rubocop Status
- [x] Config fixed (plugins format)
- [x] 176 offenses remain (app code only - complexity/I18n/manual review)

## Full Spec Suite
- [x] Measurements controller spec: 27 tests passing
- [ ] Full suite not run (16 failures in knowledge_distillation_job and specialist_feedback_job specs due to vector type not available in test db)

## Next Actions (Priority Order)

1. [ ] **Run full spec suite** - verify no regressions from today's changes
2. [ ] **Test voice recording** - manual browser test with MediaRecorder
3. [ ] **Test attachment upload** - verify image/document display
4. [ ] **Update service specs** - HealthAgentService has 227 lines, needs tests
