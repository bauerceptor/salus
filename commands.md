Bug Fixes (discovered during implementation)
B1: Medication/Treatment date validation — Medication, Treatment, TreatmentRequest models now validate start_date and end_date within ±3 days. Error messages: "cannot be more than 3 days in the past/future" and "must be on or after the start date". Factory specs and model specs updated.
B2: SpecialistPatient link — Seed was passing alan.specialist (Specialist object) to specialist: attribute which expects a User. Fixed to pass alan (User).
B3: HealthAgentConversation — Removed title: assignment (column doesn't exist). Added has_many :health_agent_conversations to Account model.
New Implementation
Unit File
3 app/jobs/daily_health_checkin_job.rb + spec
4 app/jobs/weekly_progress_summary_job.rb + spec
5 app/jobs/missed_dose_followup_job.rb + spec
6 lib/tasks/proactive_messages.rake
7 config/solid_queue.yml (scheduler config)
ProactiveAgentService — app/services/proactive_agent_service.rb — direct OpenAI API calls via Net::HTTP (verified working, HTTP 200).

# Standalone LLM query (no documents needed)
uv run librarian-cpl-fixed.py ask "what is the effect of aspirin on liver" --no-rag

# With document retrieval (after ingesting PDFs)
uv run librarian-cpl-fixed.py ingest /path/to/medical_paper.pdf
uv run librarian-cpl-fixed.py ask "what is the effect of aspirin on liver"

# Voice query without documents
uv run librarian-cpl-fixed.py voice-ask recording.wav --no-rag



## How to trigger manually
mise exec -- bundle exec rails proactive:daily_checkin
mise exec -- bundle exec rails proactive:weekly_summary
mise exec -- bundle exec rails proactive:missed_dose_followup
mise exec -- bundle exec rails proactive:trigger_all

Running the Backend
# Start the PostgreSQL container first
podman start salus-postgres
# Run the Rails server (from project directory)
cd ~/Desktop/salus-at-time
mise exec -- bundle exec rails server -p 3000
# In a separate terminal — run SolidQueue (background jobs)
mise exec -- bundle exec rake solid_queue:work
Running Tests
cd ~/Desktop/salus-at-time
# All specs
mise exec -- bundle exec rspec
# Specific spec file
mise exec -- bundle exec rspec spec/services/health_agent_service_spec.rb
# Full proactive + model + service suite (187 examples)
TEST_POSTGRES_PORT=5454 TEST_POSTGRES_USERNAME=postgres TEST_POSTGRES_PASSWORD=postgres POSTGRES_PORT=5454 mise exec -- bundle exec rspec spec/jobs/ spec/models/medication_spec.rb spec/models/treatment_spec.rb spec/models/treatment_request_spec.rb spec/services/health_agent_service_spec.rb
# Single spec with detail
mise exec -- bundle exec rspec spec/services/health_agent_service_spec.rb --format documentation
# Run tests with coverage
COVERAGE=true mise exec -- bundle exec rspec
Migrations & Seeds
cd ~/Desktop/salus-at-time
# Migrate
mise exec -- bundle exec rake db:migrate
# If migrations fail with "already exists" errors:
psql -h localhost -p 5454 -U postgres -d salus_development -c "SELECT * FROM schema_migrations;"
# Reset and reseed (WARNING: drops database)
mise exec -- bundle exec rake db:reset
# Run seeds only
mise exec -- bundle exec rake db:seed
# Run specific seed file
mise exec -- bundle exec rails runner "load('db/seeds/en/proactive_seeds.rb')"
# Check migration status
mise exec -- bundle exec rake db:migrate:status
# Rollback one migration
mise exec -- bundle exec rake db:rollback
# Trigger proactive jobs manually
mise exec -- bundle exec rails proactive:trigger_all
mise exec -- bundle exec rails proactive:daily_checkin
mise exec -- bundle exec rails proactive:weekly_summary
mise exec -- bundle exec rails proactive:missed_dose_followup
Benchmarking
App Performance
The project has rack-mini-profiler already in the Gemfile. When the server runs, it adds a speed badge (M) to pages and supports flamegraphs:
# Enable profiling via query param: append `?debug=profile` or `?debug=memory`
# e.g., visit http://localhost:3000/health_agent/chat?debug=profile
# Flamegraph (call stack profiling)
# Visit: http://localhost:3000/?debug=profile
# Memory profiling
# Visit: http://localhost:3000/?debug=memory
Rails Performance Commands
# Profile a specific controller action
mise exec -- bundle exec rails runner "
  require 'benchmark'
  puts Benchmark.measure { User.first.health_agent_conversations.last&.health_agent_messages }
"
# Check N+1 queries with Bullet (add to Gemfile if not active)
# Then run: RAILS_ENV=development mise exec -- bundle exec rails server
# Watch logs for Bullet notifications
AI Performance
# Benchmark the HealthAgentService directly
mise exec -- bundle exec rails runner "
  require 'benchmark'
  service = HealthAgentService.new(User.first)
  result = Benchmark.measure do
    10.times do
      service.ask('Does alcohol affect my liver?')
    end
  end
  puts \"10 HealthAgentService#ask calls: #{result.real.round(2)}s\"
"
# Benchmark ProactiveAgentService (direct OpenAI)
mise exec -- bundle exec rails runner "
  require 'benchmark'
  service = ProactiveAgentService.new
  result = Benchmark.measure do
    5.times do
      service.send_daily_checkin(user: User.first)
    end
  end
  puts \"5 ProactiveAgentService calls: #{result.real.round(2)}s\"
"
# Benchmark RubyLLM vs direct OpenAI (for same prompt)
mise exec -- bundle exec rails runner "
  require 'benchmark'
  prompt = 'What are the risks of acetaminophen with alcohol?'
  r1 = Benchmark.measure { RubyLLM.ask(prompt, model: 'gpt-4o-mini') }
  puts \"RubyLLM (gpt-4o-mini): #{r1.real.round(2)}s\"
"
# Check AI response latency from logs
tail -f log/development.log | grep 'HealthAgentService\|ProactiveAgentService\|OpenAI'
Database Query Performance
# Explain analyze a slow query
mise exec -- bundle exec rails runner "
  ActiveRecord::Base.connection.execute(\"
    EXPLAIN ANALYZE SELECT * FROM health_agent_messages
    WHERE health_agent_conversation_id = 1
    ORDER BY created_at DESC LIMIT 10
  \")
"
# Total slow queries in development log
grep -c 'EXPLAIN' log/development.log



Yes! Found them in db/seeds/en/proactive_seeds.rb:
Role	Email	Password
Patient (James Dean)	dean.james@example.com	password
Specialist (Alan Smith)	smith.alan@salus.health	password
Admin	admin@salus.com	password
James Dean has chronic liver disease with medications (Ursodeoxycholic Acid, Lactulose) and 14 days of medication logs. Alan Smith is linked as his hepatologist.
