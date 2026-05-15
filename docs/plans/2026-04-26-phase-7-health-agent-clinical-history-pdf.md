# Phase 7 Plan: Clinical History PDF + EHR Foundation

## Context

Phase 6 is complete. Phase 7 focuses on building the Clinical History PDF generation system that leverages existing FHIR infrastructure, the `SpecialistPatientReportService` pattern, and adds intelligent AI-generated summaries.

**Key Discovery:** `fhir_client` (6.1.0) and `prawn` (2.5.0) are already installed. The existing `Fhir::ExportController` and `SpecialistPatientReportService` provide proven patterns to follow.

## Phase 7 Units

### Unit 1: FHIR Resource Wrapper Models (In-Memory POROs)

Reuse patterns from `~/Desktop/pseudo-ehr` — base `Resource` class with in-memory caching, `ModelHelper` concern, and domain-specific resource wrappers.

**Files to create:**
- `app/models/health_agent/resource.rb` — base PORO with caching
- `app/models/health_agent/concerns/model_helper.rb` — FHIR parsing/formatting helpers
- `app/models/health_agent/patient_record.rb` — aggregates patient FHIR data
- `app/models/health_agent/observation.rb` — observations from patient data
- `app/models/health_agent/condition.rb` — conditions/diagnoses
- `app/models/health_agent/composition.rb` — clinical document composition

**Key patterns to follow from pseudo-ehr:**
- `get_object_from_bundle()` for FHIR reference resolution
- `coding_string()`, `parse_codeable_concept()`, `system_mapping()` for FHIR formatting
- Two-tier caching: in-memory Resource instances + PatientRecordCache

**Naming:** All Health Agent FHIR models go under `app/models/health_agent/` namespace.

### Unit 2: Patient Record Service

Aggregates all patient data for PDF generation and RAG context.

**Files to create:**
- `app/services/health_agent/patient_record_service.rb` — fetches and aggregates patient data from Salus models
- `spec/services/health_agent/patient_record_service_spec.rb`

**Responsibilities:**
- Fetch measurements, diseases, medications, treatments, care history
- Format data for PDF generation
- Generate structured context for AI summary

### Unit 3: Clinical Summary AI Generation

Uses `HealthAgentService` (already built in Phase 1) to generate clinical summaries from patient data.

**Files to create:**
- `app/services/health_agent/clinical_summary_service.rb` — uses HealthAgentService for AI summaries
- `spec/services/health_agent/clinical_summary_service_spec.rb`

**Key method:** `generate_clinical_summary(patient_record)` — sends structured patient data to HealthAgentService with specialist persona for summary generation.

### Unit 4: PDF Generation Service

Builds on `SpecialistPatientReportService` pattern with enhanced AI summaries.

**Files to create:**
- `app/services/health_agent/clinical_history_pdf_service.rb` — main PDF generation
- `app/views/health_agent/clinical_history/` — template views if needed
- `spec/services/health_agent/clinical_history_pdf_service_spec.rb`

**Pattern to follow:** `SpecialistPatientReportService.call` returns PDF binary — same pattern.

**Sections to include:**
1. Header (Salus branding, Salus green #00a884)
2. Patient Information
3. AI Clinical Summary (NEW — from HealthAgentService)
4. Diagnosed Conditions (FHIR-formatted)
5. Current Medications
6. Recent Measurements (90 days)
7. Treatment History
8. Adherence Summary
9. Care History
10. Specialist Notes
11. FHIR Metadata footer

### Unit 5: Document Upload Pipeline (for Clinical Documents)

Patient can upload clinical documents (lab results, imaging reports) that get parsed and stored.

**Files to create:**
- `app/jobs/health_agent/document_processing_job.rb` — handles uploaded document parsing
- `app/models/health_agent/uploaded_document.rb` — stores document metadata and parsed content
- `db/migrate/XXXXXX_create_health_agent_uploaded_documents.rb`
- `spec/jobs/health_agent/document_processing_job_spec.rb`
- `spec/models/health_agent/uploaded_document_spec.rb`

**Route:** `POST /health_agent/documents` (specialist uploads for patient) and `POST /patient/health_agent/documents` (patient uploads)

### Unit 6: Controller + Routes

**Files to create:**
- `app/controllers/health_agent/clinical_history_controller.rb` — generates PDF
- `app/controllers/health_agent/documents_controller.rb` — handles uploads
- `config/routes.rb` — add routes

**Routes:**
```ruby
namespace :health_agent do
  resources :documents, only: [:index, :create, :destroy]
  get "clinical_history/:patient_id", to: "clinical_history#show", as: :clinical_history
end
```

### Unit 7: View Integration (Patient Timeline)

**Files to create:**
- `app/views/health_agent/clinical_history/` — HTML view for clinical history
- Dashboard integration links

**Note:** SCSS + DaisyUI 5 for styling. Follow `dash-*` BEM pattern for dashboard views only.

## Implementation Sequence

1. **Unit 1:** FHIR Resource Wrapper Models — base infrastructure
2. **Unit 2:** Patient Record Service — data aggregation
3. **Unit 3:** Clinical Summary AI Generation — AI-powered summaries
4. **Unit 4:** PDF Generation Service — document generation
5. **Unit 5:** Document Upload Pipeline — document handling
6. **Unit 6:** Controller + Routes — API endpoints
7. **Unit 7:** View Integration — UI

## Test Sequence

Run tests one by one (do NOT batch):
1. `spec/models/health_agent/resource_spec.rb`
2. `spec/models/health_agent/patient_record_spec.rb`
3. `spec/services/health_agent/patient_record_service_spec.rb`
4. `spec/services/health_agent/clinical_summary_service_spec.rb`
5. `spec/services/health_agent/clinical_history_pdf_service_spec.rb`
6. `spec/models/health_agent/uploaded_document_spec.rb`
7. `spec/jobs/health_agent/document_processing_job_spec.rb`
8. `spec/requests/health_agent/clinical_history_controller_spec.rb`
9. `spec/requests/health_agent/documents_controller_spec.rb`

## Key Dependencies

- `HealthAgentService` — already built (Phase 1)
- `HealthRagService` — already built (Phase 2)
- `RubyLLM.embed` — for AI summaries
- `prawn` — already installed
- `fhir_client` — already installed

## Notes

- **Do NOT duplicate existing FHIR infrastructure** — extend `app/services/fhir.rb` if needed
- Follow `SpecialistPatientReportService` pattern closely — it's proven
- Use `Arel.sql()` for any raw SQL (similar to HealthEmbedding pattern)
- Two-tier caching: in-memory POROs + PatientRecordCache for performance
- All Health Agent models go under `app/models/health_agent/` namespace
- All Health Agent services go under `app/services/health_agent/` namespace