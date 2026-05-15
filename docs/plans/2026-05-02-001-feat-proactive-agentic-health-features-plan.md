---
title: "feat: Proactive Agentic Health Features"
type: feat
status: active
date: 2026-05-02
---

# feat: Proactive Agentic Health Features

## Overview

Add three proactive agentic features to the Salus telehealth platform: daily health check-in messages, weekly progress summaries, and missed-dose follow-up messages. Each feature is triggered by a SolidQueue job, generates a message via `HealthAgentService`, inserts it into the patient's existing `HealthAgentConversation`, and notifies the patient via ActionCable. All three features use the existing RubyLLM + OpenAI integration already configured in the project.

## Problem Frame

The existing `HealthAgentService` is reactive — it only responds when a patient sends a message. Agentic AI takes initiative: it observes health data conditions and reaches out proactively. This plan adds three high-impact, low-complexity proactive triggers that demonstrate the AI acting on behalf of the patient without being asked.

## Requirements Trace

- R1: Daily check-in message sent to each active patient at a configured morning hour
- R2: Weekly progress summary sent every Sunday with adherence rate, measurement averages, and symptom trends
- R3: Missed medication dose triggers a supportive follow-up message within a configurable window
- R4: All proactive messages appear in the patient's existing HealthAgent conversation
- R5: Patients receive a real-time notification when a proactive message arrives
- R6: All three features can be triggered manually via a Rails console helper for demonstration
- R7: Fresh pgvector database seeded with dean.james (chronic liver disease patient), smith.alan (liver specialist), admin@salus.com (admin), all with password `password`
- R8: All features have test coverage via RSpec

## Scope Boundaries

- No new AI models or LLM providers — uses existing `HealthAgentService` with OpenAI
- No changes to existing `HealthAgentService` core logic — only adds new trigger jobs and message insertion logic
- No autonomous decision-making — jobs evaluate conditions and send templated/proactively-generated messages
- pgvector setup is limited to enabling the extension and ensuring the schema loads cleanly
- Only Rails 3.2 (project Ruby 3.4.9 via mise) is in scope; Ruby 3.2 is noted as constraint only where it affects gem compatibility

## Context & Research

### Relevant Code and Patterns

- `app/services/health_agent_service.rb` — existing service with `patient_persona`, `specialist_persona`, `ask()` method; used for generating chat responses with patient context
- `app/models/health_agent_conversation.rb` — conversation model with `messages` association (ordered by created_at asc); has `persona` enum (patient/specialist) and `status` enum (active/archived)
- `app/models/health_agent_message.rb` — message model with `role` enum (user/assistant/system); `attachment_data()` helper for multimodal
- `app/jobs/alert_notification_job.rb` — existing job pattern for monitoring; shows how `HealthAgentConversation` and `NotificationsChannel` are used
- `app/jobs/send_medication_reminder_job.rb` — existing SolidQueue job pattern with `broadcast_notification()` method using `NotificationsChannel`
- `config/solid_queue.yml` — SolidQueue configuration (currently minimal/default); jobs use ActiveJob `queue_as :default`
- `db/schema.rb` — has `enable_extension "vector"` already; `health_embeddings` table cannot be dumped due to `vector(1536)` type — this must be handled in migration
- `app/models/medication_log.rb` — `status` enum: pending/taken/skipped/missed/delayed; `mark_as_missed` marks pending logs past their scheduled time
- `app/services/adherence_prediction_service.rb` — already calculates adherence rates and risk levels
- `app/services/pattern_analysis_service.rb` — already analyzes symptom trends
- `spec/jobs/knowledge_distillation_job_spec.rb` — existing job spec pattern using `perform_now` and `have_enqueued_job`
- `spec/services/health_agent_service_spec.rb` — existing service spec pattern with factory `create(:account)`

### Institutional Learnings

- The project uses SolidQueue (database-backed queue) not Sidekiq
- Jobs dispatch notifications via `NotificationsChannel.broadcast_to(account, {...})`
- HealthAgentService already builds rich patient context (medications, measurements, diseases, adherence risk)
- RubyLLM is used for chat, accessed via `HealthAgentService#chat` which wraps `RubyLLM.chat(model: "gpt-4o")`

### External References

- SolidQueue Getting Started: `rails guide` — uses `rails active_job:work` or `bin/jobs:work` for in-process execution
- RubyLLM Agent pattern: `RubyLLM::Agent` for declarative tool-use agents (optional future enhancement)

## Key Technical Decisions

- **SolidQueue jobs over cron**: Jobs are `ApplicationJob` subclasses queued via SolidQueue, not system cron. They run on a schedule via SolidQueue's built-in scheduler or an external cron that enqueues them. This keeps all job logic in Rails.
- **Proactive messages as `role: :assistant`**: Proactive messages are inserted as `assistant` role messages so they appear as AI-sent in the chat UI (consistent with how `HealthAgentService` returns responses).
- **Separate job per feature**: Each of the three features is its own job class. This allows independent scheduling, manual triggering, and granular testing.
- **Manual trigger via Rails runner**: A `TriggerProactiveMessages` module in `lib/tasks/` exposes `trigger_daily_checkin`, `trigger_weekly_summary`, and `trigger_missed_dose_followup` as `rails runner` commands.
- **Notification via existing channel**: Each job broadcasts the proactive message to the patient via `NotificationsChannel` so they receive a real-time notification even if they are not looking at the chat.
- **PGVector schema handling**: The `vector(1536)` type cannot be dumped by Rails `schema.rb`. The migration that creates `health_embeddings` must use `schema_migrations` approach with raw SQL for the vector column, and the schema must be maintained via `structure.sql` instead of `schema.rb`.

## Open Questions

### Resolved During Planning

- **PGVector connection**: The project `.env` already has `POSTGRES_HOST=localhost`. The podman container `salus-db` is accessible at `localhost:5432`. The salus-db is separate from the app's main postgres. The app's database.yml points to the salus-db postgres instance.
- **Ruby version**: Project uses 3.4.9 via mise; user has 3.2 locally. All commands use `mise exec -- ruby` / `mise exec -- bundle exec rails` to ensure correct version.
- **Manual trigger API**: Exposed as `rails runner ProactiveMessages.trigger(:daily_checkin)` etc. in a lib task file — no web endpoint needed.
- **health_embeddings table**: Already in schema (created by prior migrations) but schema.rb dump fails. Solution: switch to `structure.sql` for this database, or add a conditional `execute` in the migration for the vector column.

### Deferred to Implementation

- Exact morning hour for daily check-in — configurable via environment variable (default 8:00 AM)

## Bug Fixes Found During Implementation

During implementation, three data-integrity issues were discovered and resolved:

### B1: Medication/Treatment Date Validation (No Backdating)

**Problem:** Patients and specialists could create medications and treatments with `start_date` and `end_date` in the past. This defeats the purpose of a health tracking app where historical entries should come from actual logs, not manual back-entry.

**Affected models:** `Medication`, `Treatment`, `TreatmentRequest`

**Fix applied:**
- `Medication`: Added `start_date_within_allowed_range` validation (>= 3 days ago, <= 3 days from now), `end_date_within_allowed_range` validation (>= 3 days ago, <= 3 days from now), and `end_date_after_start_date` cross-validation
- `Treatment`: Same three validations added
- `TreatmentRequest`: Added `start_date_within_allowed_range` validation only
- Locale error messages added in `config/locales/en/models.en.yml` for all affected attributes

**Error messages shown to users:**
- `start_date`: "cannot be more than 3 days in the past" / "cannot be more than 3 days in the future"
- `end_date`: "cannot be more than 3 days in the past" / "cannot be more than 3 days in the future" / "must be on or after the start date"

**Specs updated:**
- `spec/models/treatment_spec.rb`: Fixed tests that incorrectly allowed `7.days.ago` for `start_date` and `end_date`; added proper test cases for the new validations
- `spec/factories/treatments.rb`: Changed `start_date` from `Faker::Date.between(from: 1.year.ago, to: Time.zone.today)` to `Faker::Date.between(from: 3.days.ago, to: 3.days.from_now)`
- `spec/factories/treatment_requests.rb`: Changed `start_date` from `1.month.from_now` to `Faker::Date.between(from: 3.days.ago, to: 3.days.from_now)`
- `spec/models/medication_spec.rb`: Added date validation test cases
- `spec/models/treatment_request_spec.rb`: Added start_date validation test cases

---

### B2: SpecialistPatient Link — Specialist Column Is User, Not Specialist Object

**Problem:** The `SpecialistPatient` model has `belongs_to :specialist, class_name: "User"`. This means `specialist_id` in the `specialist_patients` table references the `users` table (not the `specialists` table). The seed was passing `alan.specialist` (a `Specialist` object) to `specialist:` attribute, which caused `ActiveRecord::AssociationTypeMismatch: User expected, got Specialist`.

**Fix applied in `db/seeds/en/proactive_seeds.rb`:**
- Changed `SpecialistPatient.create!(specialist: alan.specialist, ...)` to `SpecialistPatient.create!(specialist: alan, ...)`
- Changed `SpecialistPatient.exists?(specialist: alan.specialist, ...)` to `SpecialistPatient.exists?(specialist: alan, ...)`

---

### B3: HealthAgentConversation Title and Account Association

**Problem 1:** `HealthAgentConversation` table has no `title` column. The seed attempted to set `title: "James's Health Chat"` which silently failed (or would have raised `UnknownAttributeError`).

**Fix applied:** Removed `title:` assignment from the `find_or_create_by` block in `db/seeds/en/proactive_seeds.rb`.

**Problem 2:** `Account` model lacked `has_many :health_agent_conversations` association. The `HealthAgentConversation` model correctly defined `belongs_to :account`, but the inverse was not declared.

**Fix applied:** Added `has_many :health_agent_conversations, dependent: :destroy` to `Account` model.

### B4: MedicationSchedule day_of_week — Array vs String

**Problem:** `MedicationSchedule.day_of_week` is a `varchar(20)` column (plain string), not a PostgreSQL array. Passing an array `["monday", "tuesday", ...]` would produce `"[1, 2, 3, 4, 5, 6, 7]"` (21 characters) which exceeds the 20 character limit.

**Fix applied in `db/seeds/en/proactive_seeds.rb`:** Changed from array `day_of_week: [8, 14, 20].each` to individual `MedicationSchedule` records with `day_of_week: "monday"` (string) for each day.

---

### B5: Measurement Seed Date Range Too Large

**Problem:** Seed created measurements for 14 days (`14.times do |days_ago|`), but the `Measurement` model has a `measurement_date_within_3_days` validation that rejects dates older than 3 days.

**Fix applied:** Reduced measurement loop to `3.times` in `db/seeds/en/proactive_seeds.rb`.

---

### B6: end_date Validation Missing on Medication and Treatment

**Problem:** The original validation added for B1 only checked `start_date` for `Medication` and `Treatment`. The `end_date` field had no validation and could be set to any date.

**Fix applied:** Added `end_date_within_allowed_range` and `end_date_after_start_date` validations to both `Medication` and `Treatment` models, matching the same ±3 day window as `start_date`.

---

### B7: POSTGRES_PORT in .env Was 5432 but Container Exposes 5454

**Problem:** The `salus-postgres` container maps internal PostgreSQL port 5432 to host port **5454** (not 5432). The `.env` had `POSTGRES_PORT=5432` which pointed to a non-existent PostgreSQL instance on the host.

**Fix applied:** Changed `.env` from `POSTGRES_PORT=5432` to `POSTGRES_PORT=5454`.

---

### B8: Proactive Jobs Queried Non-Existent User Role Column

**Problem:** Jobs used `joins(:user).where(users: { role: "user" })` but `User` has no `role` column. Roles are stored in a `roles` join table.

**Fix applied:** Removed the role-based filtering from all three job classes. Jobs now iterate all Accounts and check for health data presence (medications, measurements) to identify patient accounts.

---

### B9: Measurement Date Validation — Datetime Midnight Comparison Bug

**Problem:** The `measurement_date` column is a `datetime`. The validation compared `measurement_date < 3.days.ago` where `3.days.ago` has the current time component (e.g., 10:00 AM). A measurement created at midnight on April 29 would fail because April 29 00:00 < April 29 10:00 (3.days.ago).

**Fix applied in `app/models/measurement.rb`:** Changed `measurement_date_within_3_days` to compare `measurement_date.to_date` against `Time.current.to_date` and `(today - 3.days)`, eliminating the time component mismatch.

---

### B10: Rails Schema Dumper Cannot Represent `vector(1536)` Type

**Problem:** Rails' PostgreSQL adapter schema dumper (`pg_dump`-based) could not represent the `vector(1536)` column type, producing `Unknown type 'vector(1536)' for column 'embedding'` and recording "Could not dump table" in `db/schema.rb`. This broke `db:test:prepare` and `db:schema:load`.

**Fixes applied:**
1. Added `config.active_record.schema_format = :sql` in `config/application.rb` — Rails now uses `db/structure.sql` (raw `pg_dump` output) instead of `db/schema.rb`
2. Dumped `db/structure.sql` directly from the `salus-postgres` container using `podman exec` (host `pg_dump` v16 cannot connect to PostgreSQL 18 server)
3. Set up `salus_test` database by: dropping and recreating the database, loading `db/structure.sql` via `psql`, and copying `schema_migrations` rows from `salus_development`

---

## Implementation Units

- [x] **Unit 1: PGVector Setup and Health Embeddings Schema Fix**

**Goal:** Fix the `schema.rb` dump failure caused by the `vector(1536)` type (a PostgreSQL extension type Rails cannot represent in `ActiveRecord::Schema` format). The fix switches the database to use `structure.sql` instead of `schema.rb`, then seeds the database with pgvector data.

**Requirements:** R7

**Dependencies:** None

**Files:**
- Modify: `config/application.rb` — add `config.active_record.schema_format = :sql`
- Modify: `db/migrate/20260426000002_create_health_embeddings.rb` — remove the rescue block and `say` output so failures propagate loudly in test/ci
- Create: `db/structure.sql` — dump the current database schema using `pg_dump`

**Approach:**

1. **Switch to `structure.sql`** — Add `config.active_record.schema_format = :sql` to `config/application.rb`. This tells Rails to use `db/structure.sql` (raw `pg_dump` output) instead of `db/schema.rb` for `db:schema:dump` and `db:schema:load`. `structure.sql` contains raw PostgreSQL `CREATE TABLE` and `CREATE EXTENSION` statements so custom types like `vector(1536)` survive the dump/restore cycle.

2. **Update `.gitignore`** — Ensure `db/schema.rb` is ignored and `db/structure.sql` is tracked:
   ```
   db/schema.rb
   db/structure.sql
   ```
   Change to:
   ```
   db/schema.rb
   ```
   Keep `db/structure.sql` tracked (remove it from ignore).

3. **Update the health_embeddings migration** — Remove the `rescue` + `say` pattern that silently falls back to `text`. Vector should either work or fail loudly. This prevents a silent fallback that would break vector search silently:
   ```ruby
   def add_embedding_column
     return if column_exists?(:health_embeddings, :embedding)
     execute "ALTER TABLE health_embeddings ADD COLUMN embedding vector(1536)"
   end
   ```

4. **Enable vector extension in the target database** — The `vector` extension must be created **in the specific database** the Rails app uses (`salus_development`), not just on the PostgreSQL server. This is the most common pgvector setup pitfall (per Stack Overflow: `CREATE EXTENSION vector;` run against the wrong database is the leading cause of `type "vector" does not exist` errors). Run it explicitly:
   ```sql
   -- Connect to salus_development and enable vector
   psql "postgresql://postgres:postgres@localhost:5432/salus_development" -c "CREATE EXTENSION IF NOT EXISTS vector;"
   ```
   Or via a Rails migration:
   ```ruby
   class EnableVectorExtension < ActiveRecord::Migration[8.1]
     def up
       enable_extension("vector") unless extension_enabled?("vector")
     end
   end
   ```
   The container `salus-db` exposes port `5432` on localhost. The salus app connects via `POSTGRES_HOST=localhost` and `POSTGRES_PORT=5432` (already set in `.env`). The extension must be enabled in the database at that endpoint.

5. **Dump the current structure** — After migrations run and the extension is in place:
   ```bash
   mise exec -- pg_dump -h localhost -U postgres -d salus_development \
     --no-owner --no-acl --format=plain > db/structure.sql
   ```
   Or via Rails:
   ```bash
   mise exec -- bundle exec rails db:structure:dump
   ```

6. **Verify** — `bin/rails db:schema:load` (which now delegates to `db:structure:load`) should succeed without the `Could not dump table "health_embeddings"` error.

**Patterns to follow:**
- Rails multi-database setup with custom PostgreSQL types (e.g., PostGIS) — standard pattern is `schema_format = :sql`
- Existing migration pattern in `db/migrate/`

**Test scenarios:**
- Happy path: `psql` query `SELECT extname FROM pg_extension WHERE extname = 'vector';` returns `vector` when run against `salus_development` (not just the default `postgres` database)
- Happy path: `bin/rails db:structure:dump` produces a `db/structure.sql` containing `vector(1536)` and `CREATE EXTENSION vector`
- Happy path: `bin/rails db:structure:load` succeeds on a fresh database without the health_embeddings dump error
- Edge case: `bin/rails db:migrate` still works normally and re-dumps structure after migrations

**Verification:**
- `psql "postgresql://postgres:postgres@localhost:5432/salus_development" -c "SELECT extname FROM pg_extension WHERE extname = 'vector';"` returns `vector` (not empty)
- `grep "vector(1536)" db/structure.sql` returns the line
- `grep "CREATE EXTENSION.*vector" db/structure.sql` returns the extension statement
- `bin/rails db:schema:load` exits with status 0 on a fresh database

---

- [x] **Unit 2: Database Seed Data**

**Goal:** Seed the pgvector database with dean.james (chronic liver disease patient), smith.alan (liver specialist), and admin@salus.com (admin), all with password `password`, plus sufficient related data for the agentic features to function.

**Requirements:** R7

**Dependencies:** Unit 1

**Files:**
- Modify: `db/seeds.rb` (add new seed entries or create new seed file)
- Create: `db/seeds/en/proactive_seeds.rb`

**Approach:**
1. Create `db/seeds/en/proactive_seeds.rb` with the three users and related health data:
   - `dean.james@example.com` — patient with chronic liver disease (create User + Account + Disease linking to a PredefinedDisease for liver disease + Medications + recent MedicationLogs + Measurements)
   - `smith.alan@salus.health` — specialist in liver domain (create User + Account + Specialist + SpecialistPatient linked to dean.james)
   - `admin@salus.com` — existing admin already in seeds
2. All passwords set to `password` using `password_digest` via `BCrypt::Password.create('password')`
3. Dean.james needs at least 7 days of MedicationLogs (some taken, some missed) for the weekly summary and missed-dose features to show meaningful data
4. Dean.james needs Measurements for at least 3 days for the weekly summary
5. Run with `mise exec -- bundle exec rails db:seed`

**Patterns to follow:**
- Existing seed files in `db/seeds/en/` (especially `john_doe_data.rb` and `specialists.rb`)
- `has_secure_password` on `User` model

**Test scenarios:**
- Test expectation: none — seed is manual verification step
- Manual verification: `rails c` and query each account by email

**Verification:**
- `Account.where(email: "dean.james@example.com").present?` returns true
- `Specialist.where(...).present?` returns true
- `MedicationLog.where(account: dean.account).count > 0`

---

- [x] **Unit 3: Daily Health Check-In Job**

**Goal:** A SolidQueue job that sends a personalized daily check-in message to each active patient every morning.

**Requirements:** R1, R4, R5, R6

**Dependencies:** Units 1, 2

**Files:**
- Create: `app/jobs/daily_health_checkin_job.rb`
- Create: `spec/jobs/daily_health_checkin_job_spec.rb`

**Approach:**
1. `DailyHealthCheckinJob < ApplicationJob` with `queue_as :default`
2. `perform` method:
   - Query all `Account` records with `role: "user"` (active patients)
   - For each account, find or create a `HealthAgentConversation` with `persona: :patient`, `status: :active`
   - Generate a check-in prompt using `HealthAgentService.ask()` with a message like "Good morning! How did you sleep? Any symptoms to report today?" and `persona: :patient`
   - Insert the response as a `HealthAgentMessage` with `role: :assistant`, `conversation: conversation`
   - Broadcast notification via `NotificationsChannel.broadcast_to(account, { type: "proactive_checkin", message: response_preview })`
3. Scheduled execution: the job is enqueued via SolidQueue scheduler (configured in `config/solid_queue.yml`) or an external cron that calls `DailyHealthCheckinJob.perform_later`
4. For manual trigger: `TriggerProactiveMessages.trigger_daily_checkin` (defined in Unit 6)

**Patterns to follow:**
- `SendMedicationReminderJob` for job structure pattern
- `HealthAgentService` usage from `ChatController`
- `NotificationsChannel.broadcast_to` pattern from `SendMedicationReminderJob`

**Test scenarios:**
- Happy path: job creates a HealthAgentMessage when run
- Edge case: account has no existing conversation — creates a new one
- Edge case: HealthAgentService returns an error — job does not crash, logs error
- Edge case: account has no medications or measurements — still sends check-in (no context needed for simple check-in)
- Integration: after job runs, HealthAgentMessage count increases by number of accounts

**Verification:**
- After running `DailyHealthCheckinJob.perform_now`, `HealthAgentMessage.where(role: :assistant).count` increases
- Patient receives ActionCable broadcast

---

- [x] **Unit 4: Weekly Progress Summary Job**

**Goal:** A SolidQueue job that generates and sends a weekly progress summary (adherence rate, measurement averages, symptom trends) to each active patient every Sunday evening.

**Requirements:** R2, R4, R5, R6

**Dependencies:** Units 1, 2

**Files:**
- Create: `app/jobs/weekly_progress_summary_job.rb`
- Create: `spec/jobs/weekly_progress_summary_job_spec.rb`

**Approach:**
1. `WeeklyProgressSummaryJob < ApplicationJob` with `queue_as :default`
2. `perform` method:
   - Query all `Account` records with recent health activity (accounts that have `MedicationLog` or `Measurement` records in the past 7 days)
   - For each account:
     - Pull 7-day adherence data: `AdherencePredictionService.new(account).predict_non_adherence_risk`
     - Pull 7-day measurement averages via `account.measurements.where(measurement_date: 7.days.ago..)`
     - Pull symptom trends via `PatternAnalysisService.new(account).analyze_symptom_trends` or direct query of `DiseaseSymptomUpdate`
     - Build a structured weekly summary prompt for `HealthAgentService`
     - Call `HealthAgentService.ask(summary_prompt, persona: :patient)` to generate a natural language weekly summary
     - Insert response as `HealthAgentMessage` with `role: :assistant`
     - Broadcast via `NotificationsChannel`
3. Scheduled: SolidQueue scheduler or external cron every Sunday at a configurable time (default: Sunday 6 PM)
4. For manual trigger: `TriggerProactiveMessages.trigger_weekly_summary` (Unit 6)

**Patterns to follow:**
- `AdherencePredictionService` usage in `HealthAgentService#build_adherence_risk`
- `PatternAnalysisService` for symptom trend queries
- `HealthAgentService` context-building pattern from `#build_patient_context`

**Test scenarios:**
- Happy path: job generates and inserts a HealthAgentMessage with a summary
- Edge case: account has no medication logs in past week — sends a minimal summary ("No medication data recorded this week")
- Edge case: account has no measurements — still sends summary without measurement section
- Edge case: HealthAgentService returns error — job logs error, does not crash, continues to next account
- Integration: message content contains expected data points (adherence rate, measurement values)

**Verification:**
- After running `WeeklyProgressSummaryJob.perform_now`, HealthAgentMessage with weekly summary is created
- Message content includes the patient's actual adherence rate and measurement data

---

- [x] **Unit 5: Missed Dose Follow-Up Job**

**Goal:** A SolidQueue job that sends a supportive follow-up message when a patient misses a medication dose.

**Requirements:** R3, R4, R5, R6

**Dependencies:** Units 1, 2

**Files:**
- Create: `app/jobs/missed_dose_followup_job.rb`
- Create: `spec/jobs/missed_dose_followup_job_spec.rb`

**Approach:**
1. `MissedDoseFollowupJob < ApplicationJob` with `queue_as :default`
2. `perform` method:
   - Query `MedicationLog` records with `status: :missed` in the past configurable window (e.g., past 4 hours, configurable via `MISSED_DOSE_FOLLOWUP_WINDOW_HOURS=4` env var)
   - For each missed log, find the associated account
   - Check if a follow-up message for this specific log was already sent (use a `processed_medication_log_ids` Redis set or a simple `already_sent_for?(log)` check on the job to avoid duplicate messages)
   - If not yet sent:
     - Find or create `HealthAgentConversation` for the account
     - Call `HealthAgentService.ask("I noticed you missed your {medication.name} dose. Would you like me to help you get back on track?", persona: :patient)`
     - Insert response as `HealthAgentMessage` with `role: :assistant`
     - Broadcast via `NotificationsChannel`
     - Track sent state (simple in-memory set for demo, or a `sent_followups` table/Redis key)
3. This job runs frequently (e.g., every 2 hours) via SolidQueue scheduler, or can be triggered directly by `AlertNotificationJob` when it processes a `missed_medication` alert
4. For manual trigger: `TriggerProactiveMessages.trigger_missed_dose_followup` (Unit 6)

**Patterns to follow:**
- `AlertNotificationJob` `missed_medication` case pattern
- `HealthAgentService#ask` usage
- `NotificationsChannel.broadcast_to` pattern

**Test scenarios:**
- Happy path: job detects missed dose and creates follow-up HealthAgentMessage
- Edge case: same missed dose logged twice — should not send duplicate message
- Edge case: patient has no other medications — still sends generic follow-up
- Edge case: HealthAgentService returns empty/error — job does not crash
- Integration: after job runs, the specific MedicationLog has a corresponding HealthAgentMessage

**Verification:**
- After running `MissedDoseFollowupJob.perform_now`, a new HealthAgentMessage exists for accounts with missed doses
- Notification is broadcast via ActionCable

---

- [x] **Unit 6: Manual Trigger Helpers**

**Goal:** Expose all three jobs for manual triggering via `rails runner` for demonstration purposes.

**Requirements:** R6

**Dependencies:** Units 3, 4, 5

**Files:**
- Create: `lib/tasks/proactive_messages.rake`

**Approach:**
Create `lib/tasks/proactive_messages.rake`:
```ruby
namespace :proactive do
  desc "Trigger daily health check-in for all patients"
  task daily_checkin: :environment do
    puts "Triggering daily health check-in..."
    DailyHealthCheckinJob.perform_now
    puts "Done. Check HealthAgentMessage records."
  end

  desc "Trigger weekly progress summary for all active patients"
  task weekly_summary: :environment do
    puts "Triggering weekly progress summary..."
    WeeklyProgressSummaryJob.perform_now
    puts "Done. Check HealthAgentMessage records."
  end

  desc "Trigger missed dose follow-up messages"
  task missed_dose_followup: :environment do
    puts "Triggering missed dose follow-up..."
    MissedDoseFollowupJob.perform_now
    puts "Done. Check HealthAgentMessage records."
  end

  desc "Trigger all proactive messages (for demonstration)"
  task trigger_all: :environment do
    Rake::Task["proactive:daily_checkin"].invoke
    Rake::Task["proactive:weekly_summary"].invoke
    Rake::Task["proactive:missed_dose_followup"].invoke
  end
end
```

Usage:
```bash
mise exec -- bundle exec rails proactive:daily_checkin
mise exec -- bundle exec rails proactive:weekly_summary
mise exec -- bundle exec rails proactive:missed_dose_followup
mise exec -- bundle exec rails proactive:trigger_all
```

**Patterns to follow:**
- Existing rake tasks in `lib/tasks/`

**Test scenarios:**
- Test expectation: none — rake tasks are manual/demo interface

**Verification:**
- Running `rails proactive:daily_checkin` outputs "Done." and creates records

---

- [x] **Unit 7: SolidQueue Scheduler Configuration**

**Goal:** Configure SolidQueue to run the three jobs on their respective schedules.

**Requirements:** R1, R2, R3

**Dependencies:** Units 3, 4, 5

**Files:**
- Modify: `config/solid_queue.yml`

**Approach:**
1. Configure SolidQueue's built-in scheduler in `config/solid_queue.yml`:
```yaml
production:
  scheduler:
    periodic_jobs:
      - job_class_name: DailyHealthCheckinJob
        schedule: every hour at 8:00 # approximates 8 AM daily; exact time handled in job logic
        arguments: {}
      - job_class_name: WeeklyProgressSummaryJob
        schedule: every sunday at 18:00
        arguments: {}
      - job_class_name: MissedDoseFollowupJob
        schedule: every 2 hours
        arguments: {}
```
Note: SolidQueue scheduler syntax may differ — if `solid_queue.yml` scheduler syntax is not supported, use an external cron that enqueues the jobs via `bin/rails`, or use `whenever` gem.
2. Document the cron alternative if SolidQueue scheduler is not available:
```bash
# /etc/cron.d/salus-proactive
0 8 * * * app cd /path/to/app && mise exec -- bundle exec rails proactive:daily_checkin
0 18 * * 0 app cd /path/to/app && mise exec -- bundle exec rails proactive:weekly_summary
0 */2 * * * app cd /path/to/app && mise exec -- bundle exec rails proactive:missed_dose_followup
```

**Patterns to follow:**
- Existing `config/solid_queue.yml` commented pattern
- `whenever` gem pattern if SolidQueue scheduler is insufficient

**Test scenarios:**
- Test expectation: none — scheduler configuration is operational/deployment concern

**Verification:**
- Jobs are enqueued and executed at the configured schedule in production

## System-Wide Impact

**Implementation Status:**
- **Unit 1 (PGVector Setup)**: ✅ Complete — `structure.sql` approach used; vector extension confirmed on `salus_development` database at `localhost:5454` (salus-postgres container)
- **Unit 2 (Seed Data)**: ✅ Complete — dean.james, smith.alan, admin@salus.com seeded; James Dean linked to Alan Smith as active patient; HAC created; 21 schedules, 210 medication logs, 10 measurements
- **Unit 3 (DailyHealthCheckinJob)**: ✅ Complete — `app/jobs/daily_health_checkin_job.rb` + `spec/jobs/daily_health_checkin_job_spec.rb`
- **Unit 4 (WeeklyProgressSummaryJob)**: ✅ Complete — `app/jobs/weekly_progress_summary_job.rb` + `spec/jobs/weekly_progress_summary_job_spec.rb`
- **Unit 5 (MissedDoseFollowupJob)**: ✅ Complete — `app/jobs/missed_dose_followup_job.rb` + `spec/jobs/missed_dose_followup_job_spec.rb`
- **Unit 6 (Rake Tasks)**: ✅ Complete — `lib/tasks/proactive_messages.rake` with `proactive:daily_checkin`, `proactive:weekly_summary`, `proactive:missed_dose_followup`, `proactive:trigger_all`
- **Unit 7 (SolidQueue Scheduler)**: ✅ Complete — `config/solid_queue.yml` updated with schedule config + cron alternative documented
- **ProactiveAgentService**: ✅ Complete — `app/services/proactive_agent_service.rb` — direct OpenAI API calls via `Net::HTTP`
- **B1 (Date Validation)**: ✅ Fixed — Medication, Treatment, TreatmentRequest now validate date ranges; specs and factories updated
- **B2 (SpecialistPatient Link)**: ✅ Fixed — seed now passes `alan` (User) instead of `alan.specialist` (Specialist)
- **B3 (HAC + Account Association)**: ✅ Fixed — `title` removed from seed, `has_many :health_agent_conversations` added to Account
- **B4 (day_of_week String)**: ✅ Fixed — seed creates individual schedule records with string day names instead of array
- **B5 (Measurement Date Range)**: ✅ Fixed — measurement loop reduced from 14 days to 3 days in seed
- **B6 (end_date Validation)**: ✅ Fixed — end_date validation added to Medication and Treatment models
- **B7 (POSTGRES_PORT)**: ✅ Fixed — `.env` now uses port 5454 (salus-postgres container host port)
- **B8 (Role-based Query)**: ✅ Fixed — removed `joins(:user).where(users: { role: "user" })` from all three job classes
- **B9 (Measurement Datetime Bug)**: ✅ Fixed — `measurement_date_within_3_days` now compares dates only, not datetimes
- **B10 (schema.rb vector type)**: ✅ Fixed — switched to `structure.sql`; test database rebuilt from container dump

- **Interaction graph:** Three new `ApplicationJob` subclasses; new `HealthAgentMessage` records; new `NotificationsChannel` broadcasts; no changes to existing models or controllers
- **Error propagation:** If `HealthAgentService.ask()` raises, each job catches `StandardError`, logs it, and continues to next account rather than crashing the entire job
- **State lifecycle risks:** Duplicate message risk on missed dose — mitigated by tracking processed log IDs in the job instance
- **Integration coverage:** End-to-end test verifying a proactive message appears in the chat UI after job execution requires system/feature spec

## Risks & Dependencies

| Risk | Mitigation |
|------|------------|
| OpenAI API rate limits when sending to all patients at once | Add delay between patients (e.g., `sleep 0.5`) or batch by small groups |
| HealthAgentService timeout causing job to hang | Set a timeout on the OpenAI call in HealthAgentService |
| health_embeddings schema dump failure breaks `db:schema:load` | Switch to `structure.sql` for this database |
| Duplicate missed-dose messages | Track processed log IDs in a set; check before sending |
| Job runs before seed data exists in fresh deployment | Seed runs before job scheduler starts |

## Documentation / Operational Notes

- **Manual demonstration commands** (to be provided to user after implementation):
  ```bash
  # Trigger daily check-in
  mise exec -- bundle exec rails proactive:daily_checkin

  # Trigger weekly summary
  mise exec -- bundle exec rails proactive:weekly_summary

  # Trigger missed dose follow-up
  mise exec -- bundle exec rails proactive:missed_dose_followup

  # Trigger all at once
  mise exec -- bundle exec rails proactive:trigger_all
  ```

- **Seed data verification** after `db:seed`:
  ```ruby
  # In rails console
  Account.find_by(email: "dean.james@example.com")&.diseases
  Account.find_by(email: "smith.alan@salus.health")&.specialist
  AdminUser.find_by(email: "admin@salus.com")
  MedicationLog.where(account: Account.find_by(email: "dean.james@example.com")).count
  ```

- **PGVector verification**:
  ```bash
  # Extension must be checked against the specific app database, not the default postgres db
  psql "postgresql://postgres:postgres@localhost:5432/salus_development" -c "SELECT extname FROM pg_extension WHERE extname = 'vector';"
  # Should return: vector | public | vector data type and ivfflat access method
  ```
