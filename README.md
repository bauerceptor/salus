# Salus

<p align="center">
  <img src="app/assets/images/salus-with-name.svg" alt="Salus" width="220">
</p>

Salus is a comprehensive health intelligence platform that combines a social community for people with chronic diseases with enterprise-grade healthcare infrastructure — including HIPAA-compliant data handling, FHIR interoperability, and AI-powered health insights.

## What Salus Is About

Salus serves multiple audiences with a unified platform:

**For Patients** — Track diseases, symptoms, treatments, and measurements. Connect with peers who share your conditions. Store clinical documents securely. Generate PDF reports for your doctors.

**For Healthcare Specialists** — Monitor your patient roster, receive alerts for critical changes, send care recommendations, manage appointments, and maintain clinical notes — all within a compliant infrastructure.

**For Care Teams** — Share access to health data with caregivers and family members who help manage care.

Salus is a comprehensive health intelligence platform

### Healthcare Management

**Disease & Treatment Tracking**
- Add diseases from a predefined ICD-10 mapped catalog
- Track symptoms with severity changes over time
- Log risk factors and environmental influences
- Manage multiple treatments with effectiveness ratings
- Document conditions with photo uploads

**Health Measurements**
- Record blood pressure, blood sugar, weight, heart rate, SpO2, and custom measurements
- Automatic detection of abnormal values with configurable thresholds
- Calendar view for daily health overviews
- Interactive charts for 7/30/90-day trends
- Generate PDF reports for healthcare providers

**Medication Management**
- Complete medication tracking with dosage and frequency
- Recurring schedule management by day and time
- Medication logs with status tracking (pending, taken, missed, skipped)
- Background job reminders for scheduled doses
- Link medications to specific diseases

### HIPAA-Compliant Data Security

**AES-256-GCM Encryption**
- Active Record encryption with AES-256-GCM for sensitive health data
- Lockbox-style field-level encryption for clinical documents and attachments
- Encryption keys managed through environment variables, rotated safely
- All PHI (Protected Health Information) encrypted at rest

**Access Controls**
- Role-based access (patient, specialist, admin)
- Pundit policies governing every resource
- Shared access grants with configurable permissions
- Privacy settings for profile visibility, health data sharing, and online status

### FHIR Server & HL7 Interoperability

**FHIR R4 Export/Import**
- Full patient bundle export in FHIR R4 format
- Export conditions, observations, medication requests, care plans
- Import FHIR bundles to migrate or sync data from external systems
- ICD-10 and LOINC code system mappings

**Standards Compliance**
- HL7-compliant resource categorization
- SNOMED-CT support for conditions
- LOINC codes for laboratory observations
- DICOM metadata extraction from clinical documents

### Patient & Specialist Management

**Specialist Dashboard**
- Alert queue with severity-based prioritization (SOS, missed medication, low adherence, abnormal measurements)
- Patient roster with search and filtering
- Patient detail view with measurement trends and care history
- Care recommendations sent with clinical rationale
- Appointment scheduling and management

**Patient Features**
- Treatment request submission to specialists
- Direct messaging with assigned healthcare providers
- Care history timeline view
- Emergency alert system
- Caregiver access grants

**Specialist Request Workflow**
- Self-service request submission with specialization and credentials
- Admin approval/rejection workflow
- Badge and status elevation upon approval

### Social Features

**Community Connection**
- Disease-specific groups where members share aggregated (anonymized) health data
- Status updates with reactions and comments (powered by Hotwire)
- Personal and group posts with hashtags
- Friend requests with pending/accepted/rejected workflow
- Personalized feed from friends and disease groups

**Karma & Reputation**
- Point-based contribution system
- Badges: Newcomer, Contributor, Advocate, Expert
- Recognition for active community participation

### Clinical Documents & Reports

**Document Management**
- Upload clinical documents (lab results, imaging reports, discharge summaries)
- AI-powered document processing and information extraction
- Secure storage with AES encryption
- Document categorization and timeline view

**PDF Report Generation**
- Daily, weekly, monthly health summaries
- Clinical history reports for provider handoffs
- Prawn-based PDF generation with patient demographics, measurements, medications

### AI Health Agent (salus-engine)

The salus-engine Python layer provides local AI capabilities without external API dependencies:

**Speech to Text** — Whisper Tiny for voice input in Hindi, Urdu, or English

**PDF Reading & RAG** — BioBERT embeddings for medical document retrieval

**Custom Medical SLM** — Fine-tuned Qwen-0.5B on PubMed RCTs and drug interactions (runs locally on 8GB RAM)

**Custom Vision Model** — Image analysis for X-rays and scans using GGUF VLM

### Extensive Test Suite

Salus maintains comprehensive test coverage following test-driven development principles:

- **70+ model specs** with factories for all entities
- **Request/feature specs** for all controllers and endpoints
- **Route specs** verifying correct routing for 200+ routes
- **Integration specs** covering complete user flows
- **System specs** with Capybara for critical user journeys
- **Service specs** for business logic validation

See `docs/TEST_PLAN.md` for full testing strategy.

## Getting Started

### Prerequisites

- **Ruby** `3.4+` (using chruby)
- **NodeJS** `18+` (using nvm)
- **Yarn**
- **Docker**

### Setup

1. Clone the repository and install dependencies:
```bash
bundle install
yarn install
```

2. Create `.env` from `.env.example` and configure environment variables

3. Generate ActiveRecord encryption keys:
```bash
bin/rails db:encryption:init
```

4. Start Docker containers:
```bash
docker-compose up -d
```

5. Setup the database:
```bash
bin/setup
```

6. Run the application:
```bash
./bin/dev
```

### Sign In

Default test credentials:

**Patient:**
- Email: `john.doe@gmail.com`
- Password: `password`

**James Dean (patient with chronic liver disease):**
- Email: `dean.james@example.com`
- Password: `password`

**Alan Smith (liver specialist):**
- Email: `smith.alan@salus.health`
- Password: `password`

**Admin Dashboard:**
- Email: `admin@salus.com`
- Password: `password`

James Dean is assigned to Alan Smith as his primary care specialist.

## Admin Features

Salus includes a full admin dashboard (powered by Avo) for managing:

- Specialist requests (approve/reject)
- User management
- Platform health monitoring
- Article moderation

## Design Philosophy

The UI is designed from scratch without predefined templates, themes, or component libraries. The goal is simple, clean, and user-friendly — written by hand with Tailwind CSS and custom Stimulus controllers.

## Hotwire Implementation

Turbo and Stimulus power the interactive features: comments, reactions, friend requests, forms, and flash messages — all without full page reloads.

## Test Suite

Run the full suite:

```bash
mise exec ruby -- bundle exec rspec
```

Run specific test types:
```bash
mise exec ruby -- bundle exec rspec spec/models
mise exec ruby -- bundle exec rspec spec/requests
mise exec ruby -- bundle exec rspec spec/system
```

Note: Test database requires seeding first:
```bash
RAILS_ENV=test bin/rails db:reset
```

## I18n

Currently English-only, constrained in routes via `scope "(:locale)", locale: /en/`

## Internationalization

This project began as **chronlife**, created by maciejb2k. The original vision was a simple, friendly social platform where people managing chronic diseases could track their health, share experiences, and find community.

Salus extends that foundation into a comprehensive health intelligence platform while maintaining the community spirit that makes chronic disease management less isolating.

## AI Extension — salus-engine

The `salus-engine/` directory contains the Python inference layer for local AI features. It communicates with Rails over HTTP (FastAPI on port 8000) for voice input, PDF Q&A, and image analysis.

### Running the Engine

```bash
cd salus-engine
pip install -r requirements.txt
DATABASE_URL="postgresql://postgres:postgres@localhost:5454/salus" python main.py
```

The FastAPI server starts on `http://0.0.0.0:8000`.

## Architecture Highlights

**Service Objects** — Business logic in `/app/services/`

**View Components** — Reusable UI in `/app/components/`

**Pundit Policies** — Authorization in `/app/policies/`

**Solid Queue/Cache/Cable** — Rails 8 built-in background processing

## Contributing

1. Fork and create a feature branch
2. Write tests for new functionality
3. Ensure all tests pass and Rubocop is clean
4. Open a Pull Request

## License

This project is private and proprietary.
