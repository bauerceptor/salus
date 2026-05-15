---
title: Build Specialist (Doctor) Dashboard Module
type: feat
status: active
date: 2026-04-23
---

# Build Specialist (Doctor) Dashboard Module

## Overview

Salus is a Rails 8 chronic disease social platform connecting patients with doctors. This plan builds a comprehensive specialist (doctor) dashboard module from the ground up — replacing the current alpha-quality summary view with a real clinical workspace. The platform already has AI risk scoring, FHIR infrastructure, and chart components that are entirely unused by the doctor side. The patient-side workflow (medication logging, treatment requests) is currently free-form — patients can add medications and request treatments without doctor oversight. This plan closes those gaps.

**Target repo:** `salus`

## Problem Frame

A doctor managing 20–50 chronic disease patients on Salus today cannot:

- See measurement trends over time for an individual patient without manually scrolling raw logs
- Know which patients are on a declining trajectory before a crisis occurs
- Act on any patient without navigating deep into their profile (no quick actions)
- Export a patient's FHIR data or a consolidated PDF report
- View AI-generated risk predictions (`AdherencePredictionService#predict_non_adherence_risk`) — this service exists but its output is never surfaced to specialists
- See a patient's medication list and determine which were doctor-prescribed vs. self-reported
- Approve/reject medications the patient added without oversight
- Prescribe new medications directly to a patient (doctor-initiated flow)
- Upload external medical records into a patient's Salus profile
- Access a patient's full care history in chronological order
- Receive alerts tiered by clinical severity with mandatory acknowledgment

The **patient** can currently:
- Freely add any medication (no doctor approval)
- Request treatments (awaiting doctor approval)
- Export their own FHIR data
- See their own measurement trends with a time scrubber
- Chat with their linked specialists in real time

The **doctor** (specialist) cannot do any of the above at a dashboard level.

## Requirements Trace

- R1. Specialists see all their active patients with fuzzy search, risk-level filtering, and disease-type filtering
- R2. Specialists see per-patient measurement trends (blood pressure, blood sugar, weight) over configurable time windows (7/30/90 days) — matching patient dashboard depth
- R3. Specialists see AI-generated adherence risk predictions (`AdherencePredictionService#predict_non_adherence_risk`) as annotated risk cards on each patient's profile, showing risk level, specific factors, predicted adherence rate, and AI recommendation
- R4. Specialists act immediately on any patient without leaving the dashboard context: add clinical note, send medication recommendation, send treatment recommendation, or schedule an appointment
- R5. Specialists export any patient's health data as FHIR JSON (using existing `BundleExporter`) or a consolidated PDF report
- R6. Specialists import external patient records (FHIR JSON upload) merged into the patient's Salus profile — reusing existing FHIR import infrastructure
- R7. Alerts are tiered by clinical severity (Critical/Warning/Info) with distinct visual treatment and mandatory explicit acknowledgment before clearing
- R8. Medication workflow: **patient-initiated request** → doctor approves/rejects; **doctor-initiated prescription** → patient accepts/declines. Both flows coexist. Doctor can also freely add medications on behalf of a patient.
- R9. Treatment workflow mirrors medication: **patient requests treatment** → doctor approves/rejects; **doctor prescribes treatment directly** → patient accepts/declines. Both flows coexist. Doctor can also freely prescribe treatments.
- R10. Care history renders as a reverse-chronological unified timeline (30-day default, with full-history access), mixing all clinical events: diagnoses, medication starts/ends, treatment updates, recommendations, notes, messages, appointments
- R11. Admin assigns patients to doctors, registers new doctors, and manages platform-level decisions — **deferred to admin module**

## Scope Boundaries

**In scope (this plan):**
- All specialist dashboard controllers, views, services, and JavaScript behaviors
- Medication approval workflow (patient requests + doctor-initiated prescribing)
- Treatment approval workflow (patient requests + doctor-initiated prescribing)
- FHIR export and import for specialists
- AI risk prediction surfacing
- Alert tiering and acknowledgment
- Care history timeline
- Quick-action toolbar

**Out of scope:**
- Admin module (patient assignment, doctor registration, platform management) — deferred
- Patient-facing changes (patient dashboard, medication logging UX)
- AI agent training or modification
- New AI model integration
- Billing, insurance, or scheduling payment flows
- FHIR import beyond what already exists at `/fhir/import`

### Deferred to Future Iterations

- Bulk export across multiple patients (requires checkbox selection on patients index)
- Predictive alert engine that fires alerts on trajectory probability (requires `PatternAnalysisService` integration into a background job)
- Emergency command console (full-screen SOS mode — depends on WebSocket alert infrastructure already in place via `SpecialistAlertsChannel`)
- Referral package email delivery with FHIR endpoint routing
- Real-time collaborative chart annotations

## Context & Research

### Relevant Code and Patterns

| Pattern | Location |
|---|---|
| Specialist dashboard controller | `app/controllers/specialist/dashboard_controller.rb` |
| Patient detail controller (specialist view) | `app/controllers/specialist/patients_controller.rb` |
| Patient detail view | `app/views/specialist/patients/show.html.erb` |
| Dashboard view | `app/views/specialist/dashboard/index.html.erb` |
| SpecialistNotification model | `app/models/specialist_notification.rb` |
| SpecialistPatient model | `app/models/specialist_patient.rb` |
| SpecialistRecommendation model | `app/models/specialist_recommendation.rb` |
| SpecialistNote model | `app/models/specialist_note.rb` |
| SpecialistMessage model (chat) | `app/models/specialist_message.rb` |
| SpecialistAppointment model | `app/models/specialist_appointment.rb` |
| TreatmentRequest model | `app/models/treatment_request.rb` |
| AdherencePredictionService | `app/services/adherence_prediction_service.rb` |
| PatternAnalysisService | `app/services/pattern_analysis_service.rb` |
| FHIR BundleExporter | `app/services/fhir/export/bundle_exporter.rb` |
| FHIR BundleImporter | `app/services/fhir/import/bundle_importer.rb` |
| Patient dashboard (comparison) | `app/views/dashboard/index.html.erb` |
| Patient medications controller | `app/controllers/medications_controller.rb` |
| Medication model | `app/models/medication.rb` |
| Treatment model | `app/models/treatment.rb` |
| Measurement model | `app/models/measurement.rb` |
| Account model | `app/models/account.rb` |
| Chartkick + groupdate | Gem: `chartkick`, `groupdate` |
| Pagy pagination | `pagy` gem (already in use) |
| Tailwind + DaisyUI + Hotwire | Rails 8 asset pipeline |

### Existing Workflow Analysis

**Medication (current state):**
- `MedicationsController` allows patients to `create` medications freely
- No approval gate exists — `medication.approved?` or similar does not exist on the model
- No `MedicationRequest` model exists — medications go directly to `medications` table

**Treatment (current state):**
- `TreatmentRequest` model exists with statuses: `pending/approved/rejected`
- Patient creates `TreatmentRequest` → doctor approves/rejects via `TreatmentRequestsController`
- Doctor cannot prescribe treatments directly (no `SpecialistTreatment` or equivalent)

**FHIR Import (current state):**
- Exists at `/fhir/import` — patient-facing upload endpoint
- Doctors have no equivalent import UI

**Chat (current state):**
- `SpecialistMessagesController` + `specialist/messages/` views — WhatsApp-style thread per patient
- Already works in real time (ActionCable channels likely in use)

**Alerts (current state):**
- `SpecialistNotification` has 6 types: `sos_alert`, `missed_medication`, `low_adherence`, `abnormal_measurement`, `new_message`, `recommendation_response`
- `notification_color` maps to red/yellow/blue but is only used for CSS
- No acknowledgment model — `is_read` is passive and auto-clears on read

## Key Technical Decisions

### Medication Workflow

Two coexisting flows:

1. **Patient-initiated:** Patient requests a medication via a new `MedicationRequest` model → appears in doctor's dashboard as a pending request → doctor approves (creates the `Medication` record linked to the request) or rejects
2. **Doctor-initiated:** Doctor proactively prescribes a medication via `SpecialistRecommendation` with `recommendation_type: "medication"` → patient receives it as a recommendation → patient accepts (creating the `Medication` record) or declines

The `SpecialistRecommendation` path already exists for doctor-initiated medication suggestions. A new `MedicationRequest` model + `PatientMedicationRequest` flow handles the patient-initiated approval path.

### Treatment Workflow

Mirrors medication exactly:

1. **Patient-initiated:** `TreatmentRequest` already exists and is approved/rejected by doctors
2. **Doctor-initiated:** Doctor sends a `SpecialistRecommendation` with `recommendation_type: "treatment"` → patient accepts/declines → accepted creates the `Treatment` record

### Time Scrubber

Reuse Chartkick with `groupdate` for 7d/30d/90d bucketing. URL param `?period=30` drives the controller query, matching the patient dashboard pattern already in use.

### AI Prediction Surfacing

Call `AdherencePredictionService#predict_non_adherence_risk` in `Specialist::PatientsController#show` and cache for 1 hour via `Rails.cache`. Pass to the view as `@adherence_prediction` — rendered as a colored risk card above the stat cards.

### Tiered Alerts with Acknowledgment

Add `acknowledged_at` (datetime, nullable) to `specialist_notifications` via migration. Extend scopes: `.unacknowledged`, `.critical`, `.warning`, `.info`. Acknowledgment action via Turbo Stream. Alerts clear from dashboard widget only when explicitly acknowledged.

### FHIR Export

Add `Specialist::PatientsController#export_fhir` action delegating to existing `Fhir::Export::BundleExporter`. No new service code needed.

### FHIR Import for Specialists

Reuse existing `Fhir::Import::BundleImporter` via a new `Specialist::PatientsController#import_fhir` action. Authorization: verify specialist-patient link before importing.

### Care History Timeline

`CareHistoryService` aggregates all events (diseases, medications, treatment_updates, specialist_notes, specialist_recommendations, messages, appointments) into one reverse-chronological array. 30-day default scope with "load full history" affordance.

## Output Structure

    app/
      controllers/
        specialist/
          patients_controller.rb       # modify: add chart_data, adherence_prediction, export_fhir, import_fhir
          notifications_controller.rb # modify/add: acknowledge action
      javascript/
        controllers/
          patient_filter_controller.js    # new: fuzzy search + risk filter
          alert_ack_controller.js        # new: alert acknowledgment via Turbo Stream
          quick_actions_controller.js    # new: sticky quick-action toolbar
          care_stream_controller.js      # new: collapsible care history timeline toggle
      models/
        medication_request.rb        # new: patient-initiated medication approval workflow
      services/
        patient_care_history_service.rb          # new: aggregates all patient events into chronological timeline (named to avoid Specialist namespace conflict)
        patient_report_service.rb                # new: PDF generation for specialists
      views/
        specialist/
          dashboard/
            _quick_actions_toolbar.html.erb      # new: sticky action bar
            _alert_feed.html.erb                 # new: tiered alert sections
          patients/
            _measurement_charts.html.erb        # new: Chartkick trend charts
            _time_scrubber.html.erb              # new: 7d/30d/90d period selector
            _adherence_prediction.html.erb       # new: AI risk card
            _medication_requests.html.erb        # new: pending medication requests
            _treatment_requests.html.erb         # new: pending treatment requests
            _care_stream.html.erb                # new: unified timeline
            _fhir_import_form.html.erb           # new: FHIR upload for specialists
            show.html.erb                        # modify: add all new partials
            index.html.erb                        # modify: add search + filter chips
          shared/
            _quick_actions_toolbar.html.erb      # new: shared toolbar partial
            _search_results.html.erb             # new: search results partial
          notifications/
            index.html.erb                        # new: dedicated alert management page
    db/
      migrate/
        YYYYMMDDHHMMSS_add_acknowledged_at_to_specialist_notifications.rb
        YYYYMMDDHHMMSS_create_medication_requests.rb

## Implementation Units

- [ ] **Unit 1: Patient List Enhancements — Search, Filter, and Sort**

**Goal:** Replace the static patient list with searchable, filterable, sortable patient roster. A doctor with 30–50 patients must find a patient in under 3 seconds.

**Requirements:** R1

**Dependencies:** None

**Files:**
- Modify: `app/controllers/specialist/patients_controller.rb`
- Modify: `app/views/specialist/patients/index.html.erb`
- Create: `app/javascript/controllers/patient_filter_controller.js` (Stimulus)
- Create: `app/views/specialist/patients/_patient_row.html.erb`

**Approach:**
- Add `query` and `risk_filter` params to `PatientsController#index`
- Scope patients: `.where(risk_level: params[:risk_filter])` when filter present; fuzzy search via ILIKE on `full_name`
- Render filter chips: All / High Risk / Medium Risk / Low Risk — clicking sets param and Turbo-navigates
- Patient row gets hover-revealed action strip: "Add Note", "Send Medication", "Send Treatment", "Message"
- "Send Medication" and "Send Treatment" link to `new_specialist_recommendation_path(patient_id: sp.account_id, type: "medication"|"treatment")`

**Patterns to follow:**
- Pagy pagination already in use in `patients_controller.rb`
- Filter chips from patient dashboard: `<a href="?period=30">` with active class toggle
- Hover action strip: check if any existing list uses this pattern; if not, implement with CSS opacity transition

**Test scenarios:**
- Happy path: `GET /specialist/patients?risk_filter=High` returns only High-risk patients
- Happy path: `GET /specialist/patients?q=John` returns patients whose name matches "John" (case-insensitive)
- Edge case: empty results — renders "No patients found" empty state with clear search affordance
- Edge case: invalid `risk_filter` param silently ignored, falls back to all patients

**Verification:**
- Patient list renders with filter chips and search input
- Active chip shows visually selected state
- Hover reveals action buttons on each patient row

---

- [ ] **Unit 2: Measurement Trends with Time Scrubber**

**Goal:** Add per-patient Chartkick trend charts (blood pressure, blood sugar, weight) to `Specialist::PatientsController#show` with a 7/30/90-day time scrubber.

**Requirements:** R2

**Dependencies:** None

**Files:**
- Modify: `app/controllers/specialist/patients_controller.rb`
- Modify: `app/views/specialist/patients/show.html.erb`
- Create: `app/views/specialist/patients/_measurement_charts.html.erb`
- Create: `app/views/specialist/patients/_time_scrubber.html.erb`

**Approach:**
- In `PatientsController#show`, compute `@chart_data` scoped to `@patient` and `params[:period]` (default: 30)
- `@chart_data` structure mirrors patient dashboard: `{ blood_pressure: { labels: [], values: [], unit: "mmHg" }, blood_sugar: {...}, weight: {...} }`
- Use `groupdate` for bucketing: `Measurement.where(account: @patient).group_by_day(:measured_at).count`
- Time scrubber: 3 links (7 days / 30 days / 90 days) — clicking sets `?period=` and Turbo-navigates
- Render separate charts per measurement type using Chartkick `line_chart`
- Empty state when no measurements for period (reuse patient dashboard empty state pattern)

**Patterns to follow:**
- Patient dashboard chart structure: `app/views/dashboard/index.html.erb` lines 164–179
- `groupdate` bucketing: `Measurement.all.group_by_day(:measured_at).count`
- Chartkick `curve: false` (flat lines) from existing specialist dashboard `line_chart` call

**Test scenarios:**
- Happy path: `GET /specialist/patients/:id?period=30` renders 30-day blood pressure trend chart
- Happy path: switching to "7 days" re-renders charts with correct 7-day data
- Edge case: patient has no measurements — empty state renders in place of charts
- Edge case: patient has only blood pressure readings — renders only BP chart, not empty sugar/weight charts
- Edge case: period param is invalid (not 7/30/90) — defaults to 30

**Verification:**
- Charts render with correct data for the selected time period
- Time scrubber links update the chart display on click
- Empty state shown when no data for the period

---

- [ ] **Unit 3: AI Adherence Risk Predictions**

**Goal:** Surface `AdherencePredictionService#predict_non_adherence_risk` output on the patient detail view as an annotated risk card — risk level, specific factors, predicted adherence rate, and AI recommendation text.

**Requirements:** R3

**Dependencies:** None

**Files:**
- Modify: `app/controllers/specialist/patients_controller.rb`
- Create: `app/views/specialist/patients/_adherence_prediction.html.erb`
- Spec: `spec/services/adherence_prediction_service_spec.rb`

**Approach:**
- In `PatientsController#show`, call `AdherencePredictionService.new(@patient).predict_non_adherence_risk(7)` and assign to `@adherence_prediction`
- Cache with `Rails.cache.fetch("adherence_prediction/#{@patient.id}", expires_in: 1.hour)`
- Render `_adherence_prediction.html.erb` as a colored stat card above the existing stat cards
- Card content: risk level badge (HIGH/MODERATE/LOW with color), factor list (each factor as a bullet), predicted adherence rate %, AI recommendation text
- If service returns `"Insufficient data for prediction."`, render a neutral "Not enough data for AI prediction" state

**Patterns to follow:**
- Stat card from `show.html.erb` lines 29–48
- `SpecialistNotification#notification_color` red/yellow/blue badge system
- Color mapping: HIGH=red, MODERATE=yellow, LOW=green

**Test scenarios:**
- Happy path: patient with high missed dose rate shows HIGH risk with specific factors listed
- Happy path: patient with LOW risk shows green card with encouragement message
- Edge case: insufficient data — renders "not enough data" neutral state
- Edge case: cache miss — service called, result cached

**Verification:**
- `@adherence_prediction` is set and contains `risk_level`, `risk_factors`, `predicted_adherence_rate`
- Card color matches risk level (red/yellow/green)
- "Not enough data" state shows when service returns that string

---

- [x] **Unit 4: Medication Approval Workflow** ✅ DONE

**Goal:** Implement two coexisting medication flows: (1) patient requests medication → doctor approves/rejects; (2) doctor prescribes medication directly → patient accepts/declines.

**Requirements:** R8

**Dependencies:** None

**Files:**
- Create: `app/models/medication_request.rb`
- Create: `db/migrate/YYYYMMDDHHMMSS_create_medication_requests.rb`
- Modify: `app/controllers/medications_controller.rb` (add request-flow awareness)
- Modify: `app/models/medication.rb`
- Create: `app/controllers/specialist/medication_requests_controller.rb`
- Create: `app/views/specialist/medication_requests/index.html.erb`
- Modify: `app/views/specialist/patients/show.html.erb` (add pending medication requests section)
- Add route: `resources :medication_requests, module: :specialist` in specialist routes

**Approach:**

*Patient-initiated flow (MedicationRequest):*
- Create `MedicationRequest` model: `account_id` (patient), `medication_name`, `dosage`, `frequency`, `reason`, `status` (pending/approved/rejected), `specialist_id` (assigned doctor), `requested_at`
- When a patient requests a medication in the app, create a `MedicationRequest` instead of directly creating a `Medication`
- `Specialist::MedicationRequestsController` lists pending requests for the specialist's patients
- Doctor approves: creates `Medication` record linked to the request, sets `MedicationRequest.status = "approved"`
- Doctor rejects: sets `MedicationRequest.status = "rejected"` with optional rejection reason

*Doctor-initiated flow (SpecialistRecommendation):*
- Doctor uses existing `SpecialistRecommendation` with `recommendation_type: "medication"` — this flow already exists
- Patient accepts: creates `Medication` record linked to the recommendation
- Patient declines: sets recommendation status to "declined"

*Data model:*
- `Medication` gains `medication_request_id` (nullable) and `specialist_recommendation_id` (nullable)
- A medication's `source` can be: `"patient_request"` (from MedicationRequest approval) or `"doctor_prescription"` (from SpecialistRecommendation acceptance)

**Patterns to follow:**
- `TreatmentRequest` model as reference for approval workflow
- `SpecialistRecommendation` `after_create` notification hook pattern
- `AlertNotificationJob` for notifying doctor of new medication request

**Test scenarios:**
- Happy path: patient requests medication → appears in specialist's pending medication requests list
- Happy path: doctor approves medication request → `Medication` created with `medication_request_id` set
- Happy path: doctor rejects medication request → `MedicationRequest.status = "rejected"`
- Happy path: doctor proactively prescribes medication via recommendation → patient receives notification → accepts → `Medication` created with `specialist_recommendation_id` set
- Edge case: patient requests medication when no doctor linked — show "no specialist assigned" error, don't create request
- Edge case: medication request already approved/rejected — actions no longer available

**Verification:**
- `Specialist::MedicationRequestsController#index` lists pending requests for the specialist's patients
- Approving a medication request creates a `Medication` record
- Rejecting a medication request updates `MedicationRequest.status`
- Doctor-initiated recommendation creates `Medication` when patient accepts

---

- [x] **Unit 5: Treatment Prescribing (Doctor-Initiated)** ✅ DONE

**Goal:** Extend the treatment workflow so doctors can prescribe treatments directly (doctor-initiated) in addition to the existing patient-request flow. Currently `TreatmentRequest` is patient-initiated only.

**Requirements:** R9

**Dependencies:** None

**Files:**
- Modify: `app/models/specialist_recommendation.rb`
- Modify: `app/models/treatment.rb`
- Create: `db/migrate/20260423153512_add_prescribing_fields_to_treatments.rb`
- Create: `app/views/specialist/patients/_pending_treatment_requests.html.erb`
- Modify: `app/views/specialist/patients/show.html.erb`
- Modify: `app/views/specialist/treatment_requests/index.html.erb` (add doctor-prescribed tab)
- Modify: `app/controllers/specialist/treatment_requests_controller.rb`

**Approach:**
- Doctor-initiated: `SpecialistRecommendation` with `recommendation_type: "treatment"` already exists as a pattern
- When a patient **accepts** a doctor-initiated treatment recommendation, create a `Treatment` record linked to the `specialist_recommendation_id`
- `Treatment` model gains `specialist_recommendation_id` (nullable) and `source` (enum: `"patient_request"` vs `"doctor_prescription"`)
- `TreatmentRequest` (patient-initiated) continues to work as-is
- Patient detail view shows pending treatment requests section alongside recommendations
- Doctor sees pending treatment requests on dashboard and in `Specialist::TreatmentRequestsController#index` with tabbed interface

**Patterns to follow:**
- `SpecialistRecommendation` after_create notification pattern
- `TreatmentRequest` status workflow as reference
- `Treatment` model structure for adding new fields

**Test scenarios:**
- Happy path: doctor sends treatment recommendation → patient receives it → accepts → `Treatment` created linked to recommendation
- Happy path: patient submits treatment request → doctor approves → `Treatment` created linked to `TreatmentRequest`
- Happy path: doctor sees both flows in patient detail view under separate sections
- Edge case: patient declines both flows — recommendation or request is marked "rejected"/"declined"

**Verification:**
- Doctor can send treatment recommendation from patient detail page ✅ (existing)
- Patient sees recommendation in their dashboard and can accept/decline ✅ (existing)
- Accepting creates a `Treatment` record with correct source ✅ (implemented)
- Both flows appear in separate sections in patient detail view ✅ (implemented)
- Treatment requests index has tabs for patient requests vs doctor prescriptions ✅ (implemented)
- Migration adds `specialist_recommendation_id` and `source` to treatments table ✅ (applied)

---

- [x] **Unit 6: Tiered Alerts with Acknowledgment** ✅ DONE

**Goal:** Replace the flat chronological alert feed with severity-tiered sections. Critical alerts (`sos_alert`, `abnormal_measurement`) must be explicitly acknowledged before clearing from the dashboard.

**Requirements:** R7

**Dependencies:** None

**Files:**
- Migration: `db/migrate/YYYYMMDDHHMMSS_add_acknowledged_at_to_specialist_notifications.rb`
- Modify: `app/models/specialist_notification.rb`
- Create: `app/controllers/specialist/notifications_controller.rb`
- Create: `app/views/specialist/notifications/index.html.erb`
- Create: `app/views/specialist/dashboard/_alert_feed.html.erb`
- Create: `app/javascript/controllers/alert_ack_controller.js`
- Modify: `app/views/specialist/dashboard/index.html.erb`

**Approach:**
- Migration: add `acknowledged_at` datetime column (nullable, default `NULL`) to `specialist_notifications`
- `SpecialistNotification` gains `acknowledge!` instance method: sets `acknowledged_at = Time.current`
- Scopes: `.unacknowledged`, `.by_severity(:critical)`, `.by_severity(:warning)`, `.by_severity(:info)`
- `notification_color` already maps types to red/yellow/blue — use this for severity mapping:
  - Critical: `sos_alert`, `abnormal_measurement` → red
  - Warning: `missed_medication`, `low_adherence` → yellow
  - Info: `new_message`, `recommendation_response` → blue
- `Specialist::NotificationsController#acknowledge` action: finds notification, calls `acknowledge!`, returns Turbo Stream for inline removal
- Dashboard alert feed updated to show only **unacknowledged critical** alerts prominently; full feed on `/specialist/notifications`
- Dedicated notifications page renders three collapsible sections (Critical / Warning / Info) with unacknowledged alerts

**Patterns to follow:**
- `notification_color` from `SpecialistNotification` — use existing mapping
- Turbo Stream from `app/views/specialist/messages/create.turbo_stream.erb`
- `mark_as_read!` as reference for `acknowledge!` pattern

**Test scenarios:**
- Happy path: unacknowledged critical alert appears in Critical section; clicking "Acknowledge" marks it acknowledged and removes from section
- Happy path: acknowledged alerts do not appear in dashboard alert widget
- Happy path: SOS alert persists visually until explicitly acknowledged (pulsing red indicator)
- Edge case: no unacknowledged alerts — all three sections show empty state
- Edge case: specialist has no linked patients — no alerts shown

**Verification:**
- Critical alert requires acknowledgment before disappearing from dashboard
- Alert widget on dashboard shows only unacknowledged alerts
- Acknowledgment is timestamped and logged

---

- [x] **Unit 7: Quick-Action Toolbar** ✅ DONE

**Goal:** Add a persistent sticky toolbar on the dashboard and patient detail view enabling common actions without navigating away: add note, send medication recommendation, send treatment recommendation, schedule appointment, search patients.

**Requirements:** R4

**Dependencies:** None (Units 1 and 4 should be ready)

**Files:**
- Create: `app/views/specialist/shared/_quick_actions_toolbar.html.erb`
- Create: `app/javascript/controllers/quick_actions_controller.js`
- Modify: `app/views/specialist/dashboard/index.html.erb` (inject toolbar)
- Modify: `app/views/specialist/patients/show.html.erb` (inject toolbar)
- Modify: `app/views/layouts/specialist.html.erb` (or base layout)

**Approach:**
- Toolbar partial: `+ Note`, `+ Medication`, `+ Treatment`, `Schedule`, `Search`
- `position: sticky; top: 0` keeps toolbar visible on scroll
- **On dashboard:** all actions operate on the currently selected patient (from quick-filter or patient list click) — or show a patient selector modal first
- **On patient detail page:** patient context is pre-filled; buttons link directly to forms with `patient_id` pre-selected
- `Search` button opens a Turbo Frame modal with fuzzy patient search (matches Unit 1 filter)
- Medication/Treatment links: `new_specialist_recommendation_path(patient_id: @patient.id, type: "medication"|"treatment")`
- Schedule link: `new_specialist_schedule_path(patient_id: @patient.id)`
- Toolbar uses CSS `opacity` on hover to reveal actions on patient rows in the list context

**Patterns to follow:**
- Stimulus controller pattern from existing JS in `app/javascript/controllers/`
- Sticky layout element (check for any existing `position: sticky` in CSS)
- Patient selector modal pattern (check if any existing modal uses Turbo Frame)

**Test scenarios:**
- Happy path: toolbar is always visible without scrolling on both dashboard and patient detail
- Happy path: clicking "+ Medication" on patient detail pre-fills the recommendation form with the patient
- Happy path: clicking "Search" opens patient fuzzy search modal
- Edge case: no patient selected on dashboard — toolbar actions show patient selector first
- Edge case: on very small screens — toolbar collapses to icon-only mode

**Verification:**
- Toolbar visible on both pages without scrolling
- Action forms pre-fill patient context on patient detail page
- Search modal returns matching patients and allows navigation to patient detail

---

- [x] **Unit 8: FHIR Export and Import for Specialists** ✅ DONE

**Goal:** Add FHIR JSON export and import capabilities to the specialist patient view — reusing existing infrastructure.

**Requirements:** R5, R6

**Dependencies:** None

**Files:**
- Modify: `app/controllers/specialist/patients_controller.rb`
- Modify: `app/views/specialist/patients/show.html.erb`
- Add routes: `get "patients/:id/export_fhir"`, `post "patients/:id/import_fhir"`
- Check: `app/services/fhir/import/bundle_importer.rb`

**Approach:**

*FHIR Export:*
- `export_fhir` action: verify specialist has active `SpecialistPatient` link to `@patient`, instantiate `Fhir::Export::BundleExporter.new(@patient)`, call `to_fhir_json`, send as `application/json` download with `Content-Disposition: attachment`
- "Export FHIR" button in patient detail header, next to existing "Message" button

*FHIR Import:*
- `import_fhir` action: accept `POST` with `multipart/form-data` containing FHIR JSON file
- Verify specialist-patient link; parse via `Fhir::Import::BundleImporter`; merge into patient's record
- "Import FHIR" button opening a modal with file upload form
- Existing `Fhir::Import::BundleImporter` handles the merge logic — no new service code needed

**Patterns to follow:**
- Patient-side FHIR export: `fhir_export_bundle_path(format: :json)` at `app/views/dashboard/index.html.erb`
- `send_data` pattern from other file download controllers in the app
- Authorization check from `Specialist::PatientsController#show`

**Test scenarios:**
- Happy path: clicking "Export FHIR" downloads valid FHIR JSON file
- Happy path: uploading a valid FHIR JSON bundle imports and merges records into patient profile
- Error path: specialist without active link receives 404
- Error path: invalid FHIR JSON — returns validation error as JSON with flash message
- Edge case: empty FHIR bundle uploads successfully (valid but no entries to import)

**Verification:**
- `GET /specialist/patients/:id/export_fhir` returns valid FHIR JSON with correct Content-Disposition
- `POST /specialist/patients/:id/import_fhir` accepts and processes a FHIR JSON file
- Invalid file returns a user-friendly error message

---

- [x] **Unit 9: Care History Timeline** ✅ DONE

**Goal:** On the patient detail page, replace siloed sections (Diseases, Medications, Treatments, Notes, Messages) with a single reverse-chronological feed. Default to 30-day window with full-history access.

**Requirements:** R10

**Dependencies:** None

**Files:**
- Create: `app/services/patient_care_history_service.rb` (named to avoid conflict with `app/models/specialist.rb`)
- Create: `app/views/specialist/patients/_care_stream.html.erb`
- Create: `app/javascript/controllers/care_stream_controller.js`
- Modify: `app/controllers/specialist/patients_controller.rb` (added care history service call + `?history=full` toggle)
- Modify: `app/views/specialist/patients/show.html.erb` (care stream partial rendered in sidebar)
- Modify: `app/assets/stylesheets/components/_dashboard.scss` (care stream timeline styles)
- Spec: `spec/services/specialist/care_history_service_spec.rb` (18 examples, all passing)

**Approach:**
- `CareHistoryService#call(account, scope: :recent)` returns an array of event objects: `{ type:, title:, description:, timestamp:, icon:, severity: }`
- Event types and sources:
  - `:diagnosis` — `Disease` records with `diagnosed_at`
  - `:medication_start` — `Medication` with `created_at` (when source is approved/accepted)
  - `:medication_end` — `Medication` with `ended_at` (when set)
  - `:treatment_started` — `Treatment` with `start_date`
  - `:treatment_ended` — `Treatment` with `end_date`
  - `:treatment_update` — `TreatmentUpdate` records
  - `:note` — `SpecialistNote` (all types)
  - `:recommendation_sent` — `SpecialistRecommendation` `created_at`
  - `:recommendation_accepted` — `SpecialistRecommendation` status transition to `accepted`
  - `:recommendation_rejected` — `SpecialistRecommendation` status transition to `rejected`/`declined`
  - `:medication_request` — `MedicationRequest` `requested_at`
  - `:medication_request_resolved` — `MedicationRequest` status transition
  - `:message` — `SpecialistMessage` `created_at`
  - `:appointment` — `SpecialistAppointment` with `scheduled_at`
  - `:measurement` — `Measurement` with `measured_at` (only if clinically significant: abnormal flag)
- Default scope: last 30 days. "Load full history" link passes `?history=full` and bypasses the 30-day filter.
- Rendering: vertical timeline with color-coded left border by event category (red=clinical alert, yellow=medication/treatment, blue=communication, gray=system)
- Clicking an event expands a detail panel (Turbo Frame slide-over)
- Existing siloed sections remain as a "Detailed View" collapsible section below the timeline for doctors who prefer structured data

**Patterns to follow:**
- `SpecialistNotification#notification_color` for event-type-to-color mapping
- Timeline rendering (check for existing timeline component in `app/views/shared/`)
- Chartkick time-scrubber "recent vs full" toggle pattern

**Test scenarios:**
- Happy path: care stream shows all event types in reverse-chronological order for last 30 days
- Happy path: "Load full history" renders all events without 30-day filter
- Happy path: clicking a medication_start event expands to show medication name, dosage, frequency
- Edge case: patient with no events in 30 days but has older history — shows "No recent events. Load full history?" empty state
- Edge case: patient with no events at all — shows "No care history recorded"
- Integration: medication event appears when doctor approves medication request (not when patient requests it)

**Verification:**
- Care stream renders in place of siloed sections on patient detail page
- All event types appear with correct icon and color
- 30-day filter applies by default; full history loads on explicit request

---

- [x] **Unit 10: PDF Report Generation** ✅ DONE

**Goal:** Add a "Generate Report" button to the patient detail view that produces a consolidated PDF: patient summary, measurement trends, diseases, medications, adherence %, AI risk prediction, care history timeline, and specialist notes.

**Requirements:** R5

**Dependencies:** Unit 3 (AI prediction) ✅ DONE, Unit 9 (care history) ✅ DONE

**Files:**
- Check: `app/services/reports/generate_patient_profile_service.rb` (verify reuse possibility)
- Create: `app/services/specialist/patient_report_service.rb`
- Create: `app/views/specialist/patients/_report.html.erb` (Prawn PDF template)
- Modify: `app/controllers/specialist/patients_controller.rb`
- Modify: `app/views/specialist/patients/show.html.erb`
- Add route: `get "patients/:id/report" => "specialist/patients#report"`

**Approach:**
- First check if `Reports::GeneratePatientProfileService` exists and can be reused or adapted
- If reusable: create a specialist variant that includes AI prediction data and care history
- If not: create `Specialist::PatientReportService` following the same Prawn PDF pattern
- PDF sections: patient header (name, age, risk level, primary disease), measurement trend summary (90-day), disease list, medication list with source badge (patient-requested vs doctor-prescribed), adherence %, AI risk prediction card, care history timeline (last 30 days), specialist notes
- Controller action: call service, `send_data streaming: true` with PDF content type
- Button in patient detail header, styled to match "Export FHIR" button

**Patterns to follow:**
- Patient PDF generation if `Reports::GeneratePatientProfileService` exists
- `send_data streaming: true` for large file handling
- PDF template structure from patient-side equivalent

**Test scenarios:**
- Happy path: clicking "Generate Report" downloads a valid PDF with all sections
- Happy path: PDF contains patient name, risk level, medication list with source badges, AI prediction
- Edge case: patient with no medications — PDF renders "No medications" section
- Error path: service error — caught, flash error shown, no PDF downloaded
- Performance: patient with 500+ measurement records — PDF generates within 10 seconds

**Verification:**
- `GET /specialist/patients/:id/report` returns a PDF file
- PDF renders all sections with correct data
- PDF opens in standard PDF reader without errors

---

## System-Wide Impact

- **Interaction graph:** New routes: `GET /specialist/patients/:id/export_fhir`, `POST /specialist/patients/:id/import_fhir`, `GET /specialist/patients/:id/report`, `PATCH /specialist/patients/:id/acknowledge_notification`. Quick-action toolbar adds Stimulus controller interacting with existing forms via Turbo.
- **Error propagation:** Service errors (PDF generation, FHIR import) caught with `begin/rescue` and surfaced as flash errors. FHIR import validation errors returned as JSON with user-friendly message.
- **State lifecycle risks:** `CareHistoryService` is read-only aggregation. Prediction caching with 1-hour TTL is acceptable for clinical use. Alert acknowledgment is persisted — no lifecycle risk.
- **API surface parity:** Patient FHIR export at `/fhir/export/bundle`; specialist FHIR export at `/specialist/patients/:id/export_fhir`. Specialist import at `/specialist/patients/:id/import_fhir` mirrors patient import at `/fhir/import`.
- **Integration coverage:** Chartkick trends depend on `Measurement` model scope — verify that the queries used in `PatientsController#show` match the same scope used in patient-facing chart rendering.
- **Unchanged invariants:** Patient-facing features remain unaffected. All changes are additive to the specialist namespace.

## Risks & Mitigation

| Risk | Mitigation |
|---|---|
| `AdherencePredictionService` has hard dependency on `behavior_sequences` data that new patients won't have | Service already returns `"Insufficient data for prediction."` — handle in view with neutral empty state |
| FHIR bundle export is slow for patients with thousands of measurements | Use `send_data streaming: true` |
| FHIR import merges external data — possibility of duplicate records | BundleImporter's existing deduplication logic must be verified for specialist-scoped imports |
| Medication workflow changes require patient-facing UX updates | Coordinate with patient-side medication request flow; ensure patient sees requests they submitted |
| Care history aggregation is N+1 query heavy | Use `includes()` for eager loading of all associated records; add database indexes on `created_at` for all event tables |
| PDF generation uses significant memory | Streaming API + limit measurement history to 90 days in report |
| Alert acknowledgment zero-downtime migration | `add_column` with nullable `acknowledged_at`; backfill in separate migration |

## Documentation / Operational Notes

- Route additions: see Unit 1, 4, 7, 8, 10
- After first deployment: `rails db:migrate` for `acknowledged_at` column and `medication_requests` table
- Monitor Chartkick render performance on patients with > 500 measurement records
- Verify FHIR BundleImporter deduplication logic before enabling specialist import in production
- Alert acknowledgment UX requires user research for optimal acknowledgment flow (single-click vs. modal with notes)

## Open Questions (Deferred to Implementation)

1. **Rails.cache vs. on-demand compute** for AI prediction — depends on real-world latency of `AdherencePredictionService` on first call
2. **PDF layout and reuse** — verify patient-side PDF service/partial before finalizing reuse strategy
3. **Care history N+1** — estimate query cost and determine if indexes are needed before production load
4. **FHIR import deduplication** — verify that `BundleImporter` handles duplicate resource merging correctly for specialist-triggered imports

## Sources & References

- Patient dashboard (comparison): `app/views/dashboard/index.html.erb`
- Specialist dashboard (current): `app/views/specialist/dashboard/index.html.erb`
- Specialist patient detail: `app/views/specialist/patients/show.html.erb`
- FHIR export: `app/services/fhir/export/bundle_exporter.rb`
- FHIR import: `app/services/fhir/import/bundle_importer.rb`
- Adherence service: `app/services/adherence_prediction_service.rb`
- Pattern analysis: `app/services/pattern_analysis_service.rb`
- Medication model: `app/models/medication.rb`
- Treatment model: `app/models/treatment.rb`
- TreatmentRequest model: `app/models/treatment_request.rb`
- SpecialistNotification model: `app/models/specialist_notification.rb`
- SpecialistRecommendation model: `app/models/specialist_recommendation.rb`

---

## Implementation Architecture

### Authorization — No Pundit, Models Decide

DHH convention: authorization lives on models, not policy classes. Every model that needs protection has a method:

```ruby
# app/models/specialist_notification.rb
class SpecialistNotification < ApplicationRecord
  def editable_by?(specialist)
    specialist_patient&.specialist_id == specialist.id
  end

  def ackernable_by?(specialist)
    specialist_patient&.specialist_id == specialist.id
  end
end
```

Every controller action calls the model method before proceeding — no `authorize @notification` calls.

### Routes — REST Resources, Not Custom Actions

DHH convention: custom actions are new resources. "Acknowledge alert" → `Acknowledgment` resource. "Resolve alert" → `Resolution` resource (or embed in `Acknowledgment` with a `defer_until` field).

```ruby
# Correct (REST):
resources :notifications, module: :specialist do
  resource :acknowledgment, only: :create  # POST /notifications/:notification_id/acknowledgment
end

# Wrong (custom action):
patch "notifications/:id/acknowledge"
patch "notifications/:id/resolve"
```

**Route plan:**

```ruby
namespace :specialist do
  resources :medication_requests, only: %i[index update]  # Unit 4

  resources :notifications, only: %i[index show] do
    resource :acknowledgment, only: :create  # Unit 6
  end

  get "patients/:id/export_fhir"  => "patients#export_fhir", as: :patient_export_fhir
  post "patients/:id/import_fhir" => "patients#import_fhir", as: :patient_import_fhir
  get "patients/:id/report"       => "patients#report", as: :patient_report
end
```

### Controllers — Shallow Wrappers, No Service Objects

DHH convention: controllers are thin. They find records, call model methods, render. Business logic lives in models or POROs co-located under the model (e.g., `SpecialistNotification::Acknowledgment`).

```ruby
# app/controllers/specialist/notifications_controller.rb
class Specialist::NotificationsController < Specialist::BaseController
  def index
    @pagy, @notifications = pagy(
      current_specialist.notifications.unacknowledged.order(created_at: :desc),
      from: 1
    )
  end
end

# app/controllers/specialist/notifications/acknowledgments_controller.rb
class Specialist::Notifications::AcknowledgmentsController < Specialist::BaseController
  def create
    notification = current_specialist.notifications.find(params[:notification_id])
    notification.acknowledge!(specialist: current_specialist)
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(notification) }
      format.html { redirect_to specialist_notifications_path }
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to specialist_notifications_path, alert: "Notification not found."
  end
end
```

### Models — Business Logic Lives Here

```ruby
# app/models/specialist_notification.rb
class SpecialistNotification < ApplicationRecord
  belongs_to :specialist_patient

  scope :unacknowledged, -> { where(acknowledged_at: nil) }
  scope :critical, -> { where(type: %w[sos_alert abnormal_measurement]) }
  scope :warning,  -> { where(type: %w[missed_medication low_adherence]) }
  scope :info,     -> { where(type: %w[new_message recommendation_response]) }

  def acknowledge!(specialist:)
    raise ArgumentError, "Not authorized" unless ackernable_by?(specialist)
    update!(acknowledged_at: Time.current)
  end

  def ackernable_by?(specialist)
    specialist_patient&.specialist_id == specialist.id
  end
end
```

### Alert Resolution — Acknowledgment with Embedded Resolution

Acknowledge and resolve are the same action. The `SpecialistNotification::Acknowledgment` PORO stores the clinical note and optional defer time:

```ruby
# app/models/specialist_notification/acknowledgment.rb
module SpecialistNotification
  class Acknowledgment
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :note, :string
    attribute :defer_until, :datetime, default: nil

    def save
      return false if note.blank?

      notification.update!(
        acknowledged_at: Time.current,
        acknowledgment_note: note,
        deferred_until: defer_until
      )
      enqueue_deferral if defer_until
      true
    end
  end
end
```

The defer option (1h/4h/1d/3d/1w) sets `deferred_until`. A `SolidQueue::Job` checks `deferred_until` and re-creates the notification at the deferred time.

### Solid Queue Jobs — Shallow Wrappers

```ruby
# app/jobs/re_notify_alert_job.rb
class ReNotifyAlertJob < ApplicationJob
  def perform(notification_id)
    notification = SpecialistNotification.find(notification_id)
    return if notification.acknowledged_at.present?

    AlertNotificationJob.perform_later(notification_id)
  end
end
```

### POROs Under Models — Co-located Business Logic

Use `::` namespace to group related logic under the parent model. For example, a `CareHistoryService` becomes `Specialist::Patient::CareHistory`:

```ruby
# app/models/specialist/patient/care_history.rb
module Specialist
  class Patient
    class CareHistory
      attr_reader :account

      def initialize(account)
        @account = account
      end

      def events(scope: :recent)
        # returns array of event structs
      end
    end
  end
end
```

### Data Model

**Alert acknowledgment — nullable column (zero-downtime migration):**

```ruby
# db/migrate/YYYYMMDDHHMMSS_add_acknowledged_at_to_specialist_notifications.rb
add_column :specialist_notifications, :acknowledged_at, :datetime
add_column :specialist_notifications, :acknowledgment_note, :text
add_column :specialist_notifications, :deferred_until, :datetime
# NULL = unacknowledged (backward-compatible migration)
```

**Medication request:**

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_medication_requests.rb
create_table "medication_requests" do |t|
  t.uuid :account_id, null: false
  t.uuid :specialist_id, null: false
  t.string :medication_name, null: false
  t.string :dosage
  t.string :frequency
  t.text :reason
  t.string :status, default: "pending"
  t.text :rejection_reason
  t.datetime :requested_at
  t.timestamps
end
add_index :medication_requests, [:specialist_id, :status]
```

---

### Frontend — Hotwire + Tailwind + Stimulus

**Rails 8.1 + Hotwire stack:**
- **Turbo Drive** handles all specialist navigation — no `fetch` or `useEffect`
- **Turbo Frames** for patient detail sliding in over dashboard
- **Turbo Streams** for alert acknowledgment (removes row + updates KPI counter in one broadcast)

**Tailwind CSS + DaisyUI design tokens:**
New partials follow existing `dash-*` CSS class prefix conventions from `app/views/specialist/dashboard/index.html.erb`:
- Card containers: `dash-group`
- KPI cards: `dash-stat`
- Patient rows: `patient-list-item`
- Alert items: `alert-item alert-item--<severity>`

**Stimulus controllers:**

| Controller | File | Purpose |
|---|---|---|
| `patient-filter` | `patient_filter_controller.js` | Fuzzy search + risk chip filtering on patients index |
| `alert-ack` | `alert_ack_controller.js` | Alert acknowledgment via Turbo Stream; defer modal |
| `quick-actions` | `quick_actions_controller.js` | Sticky toolbar on patient detail; pre-fills patient context |

**Alert acknowledgment modal — pure ERB + `<dialog>`:**

```erb
<%# app/views/specialist/notifications/_resolve_modal.html.erb %>
<dialog id="resolve_alert_modal" class="modal">
  <div class="modal-box">
    <h3 class="font-bold text-lg">Resolve Alert</h3>
    <%= form_with model: @notification,
                  url: specialist_notification_acknowledgment_path(@notification),
                  data: { turbo_frame: "alert_row_#{@notification.id}" } do |f| %>
      <div class="form-group">
        <%= f.label :note, "Clinical Note (required)" %>
        <%= f.text_area :note, required: true, placeholder: "Describe action taken..." %>
      </div>
      <div class="form-group">
        <%= f.select :defer_until, [["Don't defer", ""], ["In 1 hour", 1.hour.from_now], ["In 4 hours", 4.hours.from_now]] %>
      </div>
      <div class="modal-action">
        <%= f.submit "Resolve", class: "btn btn-primary" %>
        <%= button_tag "Cancel", type: "button", class: "btn", onclick: "resolve_alert_modal.close()" %>
      </div>
    <% end %>
  </div>
</dialog>
```

**Chartkick integration — controller computes, view renders:**

```ruby
# app/controllers/specialist/patients_controller.rb
def show
  @patient = Account.find(params[:id])
  period = [7, 30, 90].include?(params[:period].to_i) ? params[:period].to_i : 30
  @chart_data = build_chart_data(@patient, period)
end

private

def build_chart_data(account, period)
  from = period.days.ago
  {
    blood_pressure: chart_series(account.measurements.blood_pressure.where(measured_at: from..), :blood_pressure_systolic, :blood_pressure_diastolic),
    blood_sugar: chart_series(account.measurements.blood_sugar.where(measured_at: from..), :value, nil),
    weight: chart_series(account.measurements.weight.where(measured_at: from..), :value, nil)
  }
end
```

**Phased delivery:**

| Phase | Units | Why | Status |
|---|---|---|---|
| **Phase 1: Core infrastructure** | Unit 6 (alerts + acknowledgment), Unit 1 (patient list search/filter) | Alert-driven workflow and patient navigation | ✅ DONE |
| **Phase 2: Patient detail** | Unit 2 (measurement charts), Unit 3 (AI prediction), Unit 9 (care timeline) | Core patient review context | ✅ DONE |

| **Phase 4: Export & Reporting** | Unit 8 (FHIR export/import), Unit 10 (PDF reports) | Data portability and referrals | 🔄 Not started |
| **Phase 5: Quick actions** | Unit 7 (quick-action toolbar) | Efficiency polish for returning doctors | ✅ DONE |
