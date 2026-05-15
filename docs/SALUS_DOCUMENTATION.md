# Salus Documentation

**Version 1.0** | *A social platform for people with chronic diseases*

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [System Architecture](#2-system-architecture)
3. [Getting Started](#3-getting-started)
4. [Data Models](#4-data-models)
5. [Authentication & Authorization](#5-authentication--authorization)
6. [User Accounts & Profiles](#6-user-accounts--profiles)
7. [Disease Management](#7-disease-management)
8. [Health Measurements](#8-health-measurements)
9. [Medications & Reminders](#9-medications--reminders)
10. [Social Features](#10-social-features)
11. [Specialist Dashboard](#11-specialist-dashboard)
12. [AI Health Agent](#12-ai-health-agent)
13. [FHIR Integration](#13-fhir-integration)
14. [Clinical Documents & Reports](#14-clinical-documents--reports)
15. [Notes & Organization](#15-notes--organization)
16. [API Reference](#16-api-reference)
17. [Deployment](#17-deployment)
18. [Testing](#18-testing)
19. [Contributing](#19-contributing)

---

## 1. Introduction

### 1.1 What is Salus?

Salus is a comprehensive social platform designed specifically for people living with chronic diseases. The platform enables users to:

- **Manage their health conditions** by tracking diseases, symptoms, treatments, and related data
- **Share experiences** with others facing similar health challenges
- **Connect with specialists** for professional guidance and recommendations
- **Monitor health metrics** through integrated measurement tracking
- **Access AI-powered support** for health-related questions and insights

### 1.2 Target Users

| User Type | Description |
|-----------|-------------|
| **Patients** | Individuals managing one or more chronic conditions who want to track their health and connect with others |
| **Caregivers** | Family members or friends who support patients in managing their health |
| **Specialists** | Healthcare professionals (doctors, nurses) who monitor and guide patients |
| **Administrators** | Platform managers who oversee specialist requests and platform health |

### 1.3 Key Features Overview

```
Health Management
├── Disease Tracking (symptoms, severity, status)
├── Measurement Recording (blood pressure, weight, sugar, etc.)
├── Medication Management with Reminders
├── Treatment Plans
└── Photo Documentation

Social Connection
├── Disease-Specific Groups
├── Status Updates & Feed
├── Friend Connections
├── Posts and Comments
└── Reactions and Engagement

Professional Care
├── Specialist Dashboard
├── Patient Monitoring
├── Care Recommendations
├── Appointment Requests
└── Clinical Notes

AI Assistance
├── Patient Health Agent
├── Specialist Decision Support
├── Pattern Recognition
└── Adherence Prediction

Data & Standards
├── FHIR Integration (Import/Export)
├── PDF Report Generation
├── Clinical Document Storage
└── Care History Timeline
```

---

## 2. System Architecture

### 2.1 Technology Stack

| Component | Technology | Version |
|-----------|-------------|---------|
| **Framework** | Ruby on Rails | 8.0 |
| **Frontend** | Hotwire (Turbo + Stimulus) | 1.4+ |
| **Styling** | Tailwind CSS + DaisyUI | 3.3 / 5.5 |
| **Database** | PostgreSQL | 15+ |
| **Cache/Queue** | Solid Queue, Solid Cache, Solid Cable | (Rails 8 built-ins) |
| **Authentication** | Devise | ~4.9 |
| **Authorization** | Pundit | ~2.5 |
| **File Storage** | Active Storage ( Shrine) | Rails built-in |
| **PDF Generation** | Prawn | 2.5 |
| **Charts** | Chartkick | 5.0 |
| **Calendar** | Simple Calendar | 2.4 |
| **AI Integration** | RubyLLM | 1.0 |

### 2.2 Project Structure

```
salus/
├── app/
│   ├── assets/
│   │   ├── stylesheets/       # SCSS and Tailwind CSS
│   │   └── builds/            # Compiled assets
│   ├── channels/              # Action Cable channels
│   ├── components/            # View components
│   │   └── ui/                # Reusable UI components
│   ├── controllers/           # Rails controllers
│   ├── helpers/               # View helpers
│   ├── javascript/             # Hotwire/stimulus JS
│   ├── jobs/                  # Background jobs
│   ├── mailers/               # Email mailers
│   ├── models/                # Active Record models
│   ├── policies/              # Pundit policies
│   ├── services/              # Business logic services
│   └── views/                 # ERB templates
├── config/
│   ├── environments/           # Environment configs
│   ├── initializers/          # Rails initializers
│   └── locales/               # I18n translations
├── db/
│   ├── migrate/               # Database migrations
│   ├── schema.rb              # Current schema
│   └── seeds/                  # Seed data
├── lib/                        # Library code
├── public/                     # Static assets
├── spec/                       # RSpec tests
└── custom-components/          # Custom component templates
```

### 2.3 Database Design

Salus uses PostgreSQL with the following extensions:

- `pg_catalog.plpgsql` - Standard PostgreSQL extension
- `pgcrypto` - For UUID generation
- `vector` - For AI/embedding support

All tables use UUID primary keys (`gen_random_uuid()`) for secure, distributed ID generation.

### 2.4 Key Design Patterns

**Service Objects**: Business logic resides in `/app/services/` service classes

**View Components**: Reusable UI elements in `/app/components/`

**Policies**: Authorization logic in `/app/policies/`

---

## 3. Getting Started

### 3.1 Prerequisites

| Dependency | Version | Purpose |
|------------|---------|---------|
| Ruby | 3.2+ | Runtime |
| NodeJS | 18+ | JavaScript runtime |
| Yarn | latest | Package management |
| Docker | latest | Containerization |
| PostgreSQL | 15+ | Database |

### 3.2 Environment Setup

**1. Clone the repository:**
```bash
git clone https://github.com/maciejb2k/salus.git
cd salus
```

**2. Install dependencies:**
```bash
bundle install
yarn install
```

**3. Configure environment:**
Create a `.env` file in the root directory based on `.env.example`:
```bash
cp .env.example .env
```

Generate ActiveRecord encryption keys:
```bash
bin/rails db:encryption:init
```

**4. Start Docker containers:**
```bash
docker-compose up -d
```

**5. Setup the database:**
```bash
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed
```

**6. Run the application:**
```bash
./bin/dev
```

### 3.3 Default Test Credentials

| Locale | Email | Password |
|--------|-------|----------|
| English | `john.doe@gmail.com` | `password` |
| Polish | `tomasz.nowak@gmail.com` | `password` |

### 3.4 Development Commands

| Command | Purpose |
|---------|---------|
| `./bin/dev` | Start development server with Hotwire |
| `bin/rails console` | Open Rails console |
| `bin/rails db:migrate` | Run pending migrations |
| `bin/rails test` | Run test suite |
| `rubocop` | Run code linter |

---

## 4. Data Models

### 4.1 Core Entities

```
User ──────< Account
              │
              ├── Disease ─────< DiseaseSymptom
              │                    └── DiseaseSymptomUpdate
              │              ├── DiseaseRiskFactor
              │              ├── DiseaseStatus
              │              ├── DiseasePhoto
              │              └── Treatment (through TreatmentDisease)
              │
              ├── Medication ─────< MedicationLog
              │                     └── MedicationSchedule
              │
              └── Measurement ─────< MeasurementType
```

### 4.2 User & Authentication

The User model handles authentication with Devise, supporting 2FA, OAuth, and secure password management.

The Account model stores profile information, karma points, badges, privacy settings, and links to all health data.

### 4.3 Disease Tracking

Diseases are linked to predefined diseases (ICD-10 mapped) and track severity, diagnosis date, and status.

### 4.4 Health Measurements

Measurements record vital signs with automatic abnormal value detection and alerting.

### 4.5 Specialist & Care

Specialists can be assigned to patients, send recommendations, and view patient data through a dedicated dashboard.

### 4.6 Social Features

Friendships, groups (disease-specific), posts, comments, and reactions enable community engagement.

### 4.7 AI Health Agent

Conversations and messages support both patient and specialist personas with safety guardrails.

---

## 5. Authentication & Authorization

### 5.1 Authentication (Devise)

Salus uses Devise with:
- Email/password authentication
- Account confirmation
- Password reset
- Two-factor authentication (2FA)
- Google OAuth integration
- Backup codes for 2FA recovery

### 5.2 Two-Factor Authentication

Users enable 2FA in Settings > Security using TOTP (Google Authenticator compatible).

### 5.3 Authorization (Pundit)

Pundit policies control access to resources based on ownership and relationships.

### 5.4 Role-Based Access

- `patient` - Default role for new users
- `specialist` - Healthcare professional
- `admin` - Platform administrator

### 5.5 Privacy Settings

Accounts control profile visibility, health data sharing, friend requests, and online status.

---

## 6. User Accounts & Profiles

### 6.1 Account Model

Profile fields include name, username, bio, birthday, phone, location, education, sex, and avatars.

### 6.2 Karma & Badges

| Badge | Points |
|-------|--------|
| Newcomer | 0-10 |
| Contributor | 11-50 |
| Advocate | 51-100 |
| Expert | 101+ |

### 6.3 Care Team

Caregivers can be granted view permissions for diseases, measurements, and medications with notification preferences.

---

## 7. Disease Management

### 7.1 Adding a Disease

Users select from predefined diseases mapped to ICD-10 codes.

### 7.2 Disease Panel Sections

| Section | Description |
|---------|-------------|
| Status Updates | Short updates about well-being with mood tracking |
| Symptoms | Track symptoms with severity over time |
| Risk Factors | Environmental/lifestyle factors |
| Treatments | Current and past treatments |
| Photos | Visual documentation |

### 7.3 Disease Statuses

Short updates about well-being with mood (1-5 scale) and notes. Support comments and reactions.

### 7.4 Symptoms Tracking

Symptoms can be predefined or custom, with severity levels (mild, moderate, severe) and intensity updates over time.

---

## 8. Health Measurements

### 8.1 Measurement Types

| Type | Unit | Normal Range |
|------|------|--------------|
| Weight | kg | User-defined |
| Heart Rate | bpm | 60-100 |
| Blood Pressure | mmHg | <130/85 |
| Blood Sugar | mg/dL | 70-100 fasting |
| SpO2 | % | 95-100 |

### 8.2 Recording Measurements

Measurements are recorded with automatic validation against normal and critical ranges.

### 8.3 Visualization

- Calendar View: Daily overview
- Charts: 7/30/90-day trends via Chartkick
- PDF Reports: Generate for healthcare providers

### 8.4 Abnormal Detection

Automatic alerts created when measurements fall outside normal ranges.

---

## 9. Medications & Reminders

### 9.1 Medication Model

Tracks name, dosage, frequency, instructions, and active status. Can be linked to diseases and medication requests.

### 9.2 Medication Schedules

Supports recurring schedules by day of week and time of day.

### 9.3 Medication Logs

Tracks each scheduled dose with status: pending, taken, missed, or skipped.

### 9.4 Reminder System

Background jobs send reminders and create alerts for missed doses.

---

## 10. Social Features

### 10.1 Friends

Friend requests with pending/accepted/rejected status. Accepted friendships enable health data visibility.

### 10.2 Groups

Disease-specific communities where users see aggregated data from all members.

### 10.3 Posts

Group or individual posts with hashtags, comments, reactions, and bookmarks.

### 10.4 Feed

Personalized feed showing posts from user, friends, and disease groups.

---

## 11. Specialist Dashboard

### 11.1 Overview

Alert queue, patient roster, messages, and notifications for healthcare providers.

### 11.2 Alert Types

| Alert Type | Severity |
|-----------|----------|
| sos_alert | Critical |
| missed_medication | High |
| low_adherence | Medium |
| abnormal_measurement | High |
| new_message | Low |
| recommendation_response | Low |

### 11.3 Patient Detail View

Measurement trends, care history timeline, pending requests, medications, and specialist notes.

### 11.4 Care Recommendations

Specialists send recommendations to patients with required clinical rationale.

---

## 12. AI Health Agent

### 12.1 Architecture

Built on RubyLLM with two personas: patient support and specialist decision support.

### 12.2 Personas

| Persona | Users | Purpose |
|---------|-------|---------|
| Patient | Patients | General health guidance |
| Specialist | Healthcare providers | Patient history analysis, pattern recognition |

### 12.3 Safety Guardrails

- Jailbreak pattern detection
- Off-topic detection
- Scope enforcement (no diagnoses/prescriptions)

### 12.4 RAG Integration

Retrieval-Augmented Generation for patient context and anonymized patterns.

---

## 13. FHIR Integration

### 13.1 Supported Endpoints

- GET /fhir/export/bundle - Full patient bundle
- GET /fhir/export/measurements - Observation resources
- GET /fhir/export/diseases - Condition resources
- GET /fhir/export/medications - MedicationRequest resources
- POST /fhir/import - Import FHIR bundle

### 13.2 Resource Mapping

| FHIR Resource | Salus Entity |
|--------------|--------------|
| Patient | Account |
| Condition | Disease |
| Observation | Measurement |
| MedicationRequest | Medication |

---

## 14. Clinical Documents & Reports

### 14.1 Clinical Documents

Upload and AI process clinical documents (lab results, prescriptions, discharge summaries, imaging reports).

### 14.2 PDF Report Generation

Generate comprehensive PDF reports using Prawn with patient demographics, measurements, medications, and care history.

### 14.3 Report Types

- Daily Summary
- Weekly Summary
- Monthly Summary
- Clinical History

---

## 15. Notes & Organization

### 15.1 Notes

Personal notes with tagging, pinning, and associations to diseases and groups.

### 15.2 Note Tags

Per-account tags for organizing notes.

---

## 16. API Reference

### 16.1 Authentication

```
POST /auth/sign_in
POST /auth/sign_up
POST /auth/password
DELETE /auth/sign_out
```

### 16.2 Core Resources

```
GET  /accounts
GET  /accounts/:id
GET  /diseases
POST /diseases
GET  /diseases/:id
PUT  /diseases/:id
DELETE /diseases/:id
GET  /measurements
POST /measurements/create/:type
GET  /groups
POST /groups/:id/join
GET  /friend_requests
POST /friend_requests
```

### 16.3 Specialist

```
GET  /specialist/patients
GET  /specialist/patients/:id
GET  /specialist/patients/search
POST /specialist/recommendations
GET  /specialist/messages
```

### 16.4 AI Agent

```
GET  /ai-agent
POST /ai-agent/messages
POST /ai-agent/conversations
DELETE /ai-agent/conversations/:id
```

---

## 17. Deployment

### 17.1 Docker

Dockerfile and docker-compose.yml for local development and production.

### 17.2 Kamal

Deployment configuration for production servers.

### 17.3 Environment Variables

Required: DATABASE_URL, REDIS_URL, SECRET_KEY_BASE, RAILS_MASTER_KEY

Optional: AWS credentials, Google OAuth, OpenAI API key

### 17.4 Background Jobs

Solid Queue configured for production with dispatchers and workers.

---

## 18. Testing

### 18.1 Test Suite

RSpec with model specs, controller specs, and service specs.

### 18.2 Running Tests

```bash
bin/rails test
bin/rails spec:models
```

### 18.3 Code Quality

Rubocop for Ruby style linting with performance extensions.

---

## 19. Contributing

### 19.1 Development Workflow

1. Fork the repository
2. Create a feature branch
3. Make changes with tests
4. Ensure tests and rubocop pass
5. Open a Pull Request

### 19.2 Code Style

Follow existing conventions, use Rubocop, keep methods under 20 lines, use Service Objects for business logic.

---

## Appendix A: Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| j/k | Navigate alerts |
| g | Go to dashboard |
| n | New post |
| / | Search |

## Appendix B: Environment Configuration

See `.env.example` for all configurable options.

## Appendix C: Third-Party Services

| Service | Purpose |
|---------|---------|
| Google OAuth | Sign in |
| OpenAI | AI Health Agent |
| AWS S3 | File storage |

---

*Documentation last updated: April 2026*
