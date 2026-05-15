---
title: feat: Admin Module - Specialist Management & Patient Assignment
type: feat
status: completed
date: 2026-04-25
origin: docs/plans/2026-04-23-001-feat-specialist-dashboard-module-plan.md
rails_conventions: true
scope_boundary_notes: "Admin = platform operations. Specialist = clinical care. No overlap."
---

# Admin Module: Specialist Management & Patient Assignment

## Overview

Build the admin module for Salus — a Rails 8 chronic disease platform where patients self-register and specialists are managed by admins. The admin module gives administrators visibility and control over specialist-patient relationships, specialist onboarding, patient-specialist assignments, and real-time chat observability.

All implementation follows TDD, DHH-style Rails patterns, and established Salus conventions. Admin and specialist modules maintain strict ownership boundaries. CSS uses `dash-*` BEM. Routes use keyword args. Business logic lives in models/POROs, not controllers.

**User-stated priorities (from ideation survivors):**
- Admins assign patients to specialists (no UI exists)
- Specialists share unique referral URLs for patient onboarding (feature missing)
- Patient "no specialist assigned" messaging (missing on patient side)
- WhatsApp chat verification (uncertain working state)
- Specialists added by admins via approval workflow (existing but minimal)
- Soft-delete deferred to separate unit — not in scope here

## Problem Frame

The admin module currently consists of: 4 controllers (base, sessions, dashboard, specialist_requests), no dedicated layout, basic specialist_request approval only. Admins cannot:
- See or manage specialist-patient assignments
- Detect patients without an assigned specialist
- Generate or track specialist referral URLs
- Verify WhatsApp chat reliability
- Approve specialist registrations via a self-service form

The existing `specialist_requests` approval workflow creates a `SpecialistRequest` but does NOT create a `SpecialistPatient` record on approval — a bug that will be surfaced and fixed. Patients can also forge a `specialist_id` in message params with no authorization check.

## Requirements Trace

- R1. Admin dashboard displays actionable cards: unassigned patients count, pending specialist requests, specialist assignments overview, chat health summary — each card links to its management surface
- R2. Admin can view all specialist-patient assignments, filter by specialist/patient/status/relationship_type, and perform single and bulk reassignments
- R3. Admin can view patients with no active specialist (orphaned) and take assignment action
- R4. Each specialist automatically has a unique referral URL (`/join/specialist/:hash`) displayed in their admin management view and in the specialist's own profile
- R5. Admin can see per-specialist referral URL analytics: clicks, registrations started, registrations completed, conversion rate
- R6. When a patient with no active specialist attempts to send a message, they see an explicit banner: "You don't have a specialist assigned. Your messages are saved but cannot be delivered until an admin assigns a specialist."
- R7. Admin can view WhatsApp-style chat health: messages sent/delivered/failed per specialist, average response time, patients with zero chat history, ActionCable connection status
- R8. Specialists can fill a self-registration form → pending state → admin vetting queue → one-click approve/reject with reason
- R9. Approving a specialist registration creates the SpecialistPatient record linking specialist to patient

## Scope Boundaries

- **In scope:** All 6 survivor ideas from ideation (Units 1-6 below)
- **Deferred to separate unit:** Specialist soft-delete with patient reassignment workflow (specialist offboarding)
- **Not in scope for this plan:** Patient intake triage, dynamic specialist types, care teams, batch bulk CSV import, automated rule-based assignment, performance tiers, scheduled digest emails

### Admin Module vs Specialist Module — Scope Separation

This is the authoritative scope boundary for dashboard and reporting work. It applies to all current and future units.

**Admin module owns (platform operations):**
- Aggregate counts and KPIs (total patients, assignment rate, orphaned count)
- Specialist capacity monitoring and load distribution
- Referral URL analytics (clicks, conversion rate, registrations)
- Patient-specialist assignment management (reassign, bulk operations)
- Vetting queue for specialist registration requests
- Time-to-assignment trend tracking
- Chat health observability (message volume, delivery rate, response time)
- Orphan detection (patients with no active specialist relationship)
- Platform-wide risk stratification counts (aggregate only)

**Specialist module owns (clinical care):**
- Per-patient vital signs (blood pressure readings, blood glucose trends)
- Per-patient medication adherence rates and missed dose tracking
- Care gap identification — screenings and follow-ups overdue per patient
- Individual patient risk scoring and risk level display
- Patient health metric charts and historical trends
- Specialist's own patient roster with clinical details

**Data access pattern:** Admin module reads aggregate data from existing models via service objects. Admin module never exposes per-patient clinical data. Specialist module owns all clinical-facing views and data.

### Deferred to Separate Tasks

- Specialist soft-delete + offboarding workflow: deferred to future unit — requires `deleted_at` column on Specialist, patient reassignment wizard, read-only enforcement for patients of inactive specialists, automated WhatsApp notification

## Context & Research

### Relevant Code and Patterns

- `app/models/specialist.rb` — fields: `specialization`, `field_of_expertise`, `specialization_description`, `user_id`
- `app/models/specialist_patient.rb` — fields: `account_id`, `specialist_id`, `relationship_type` (primary_care/consulting/specialist), `status` (pending/active/inactive), `notes`. Scopes: `active`, `pending`
- `app/models/specialist_request.rb` — hash_code method exists (`id.split("-").first.upcase`), route does NOT exist
- `app/models/user.rb` — email, password_digest, `has_one :specialist`
- `app/models/account.rb` — first_name, last_name, username, user_id
- `app/controllers/specialist/base_controller.rb` — uses `layout "specialist_dashboard"`
- `app/controllers/specialist/messages_controller.rb` — WhatsApp-style chat, no specialist relationship authorization check
- `app/views/specialist/dashboard/index.html.erb` — CSS class patterns: `dash-home`, `dash-group`, `dash-stat`, `dash-header`, `dash-button--*`
- `app/assets/stylesheets/layouts/` — `specialist_dashboard.html.erb` layout
- `config/routes.rb` — admin namespace at lines 2-31, specialist namespace at lines 167-193
- `app/assets/stylesheets/utils/_variables.scss` — color palette (teal-based `--color-primary: #0d7377`)
- `spec/requests/admin/` — existing admin specs (currently minimal)

### Critical Bugs Found During Analysis

**Bug 1: `SpecialistRequest#approve!` does not create `SpecialistPatient`**
When an admin approves a specialist request, the request is marked `approved` but no `SpecialistPatient` record is created. The patient-specialist relationship is never established. Fix: `approve!` must create a `SpecialistPatient` with `status: "active"` and `relationship_type: "primary_care"`.

**Bug 2: No authorization on `SpecialistMessagesController#create`**
Patient messages accept `specialist_id` from params with no verification that the patient has an active relationship with that specialist. A patient could forge a message to any specialist. Fix: verify `SpecialistPatient.active.exists?(account: current_account, specialist_id: params[:specialist_id])` before allowing send.

### Institutional Learnings

- Specialist dashboard uses `dash-*` BEM CSS pattern consistently
- Routes use keyword args: `specialist_patient_path(id: sp.id, locale: I18n.locale)` — never positional
- Controllers use `redirect_to path(id: resource.id), notice: "..."` pattern
- Models use `scope :active, -> { where(status: "active") }` pattern
- Strong parameters: `params.require(:resource).permit(:field1, :field2)` — only existing fields

## Key Technical Decisions

- **Admin layout:** Create `app/views/layouts/admin_dashboard.html.erb` mirroring the specialist dashboard layout pattern (sidebar nav, header, main content). NOT the application layout.
- **Referral URL route:** New route `get "/join/specialist/:hash"` (public, outside auth scope) → `Public::JoinController#specialist` action. Hash is the specialist's `hash_code` (already exists on `SpecialistRequest`). Patients visiting this URL see a pre-assignment page.
- **Analytics storage:** Referral URL clicks stored in a new `SpecialistReferralClick` model (specialist_id, clicked_at, ip_address, user_agent). Registrations tracked via `SpecialistPatient` records created through the referral flow.
- **Active specialist detection:** `SpecialistPatient.active` scope = `where(status: "active")`. A patient has an active specialist if `SpecialistPatient.active.exists?(account_id: patient.id)`.
- **Orphaned patient query:** `Account.where.not(id: SpecialistPatient.active.select(:account_id))` — patients with no active specialist-patient relationship.
- **Chat health:** Query `SpecialistMessage` and `SpecialistNotification` aggregates per specialist. No new models needed.
- **Admin specialist CRUD:** `Admin::SpecialistsController` — index (with search/filter), show, destroy (soft-delete placeholder)
- **Assignment management:** `Admin::AssignmentsController` — index (filterable), reassign single, bulk reassign

### CSS / Visual Design System

**Teal color palette (DaisyUI 5 custom theme):**
```scss
--color-primary:   #0d7377;   // Main teal — buttons, links, active states
--color-primary-dark: #0a5c61; // Hover/pressed states
--color-secondary: #14919b;   // Lighter teal — secondary actions
--color-accent:    #dd8452;   // Warm accent — highlights, warnings
--color-background: #f0f4f8;  // Page background (cool gray-white)
--color-surface:   #ffffff;   // Card/panel surface
--color-danger:    #dc3545;   // Error, critical risk, over-capacity
--color-warning:   #f0ad4e;   // Warning states, nearing capacity
--color-success:   #28a745;   // Healthy, on-track, delivered
```

**BEM naming convention (`dash-*` prefix):**
| Element | Class | Notes |
|---------|-------|-------|
| Page container | `.dash-home` | Top-level page wrapper |
| Card group | `.dash-group` | Table or card collection |
| Stat card | `.dash-stat` | KPI metric card |
| Stat icon | `.dash-stat__icon--*` | Icon inside stat (heart, users, chart) |
| Header bar | `.dash-header` | Section heading row |
| Button variants | `.dash-button--primary`, `--secondary`, `--danger` | |
| Filter chip | `.filter-chip` | Active filter indicator |
| Table row | `.dash-group__row` | Table row within group |
| Badge | `.badge--success`, `--warning`, `--danger`, `--neutral` | |

**Layout file structure:**
```
app/assets/stylesheets/
  layouts/
    _admin_dashboard.scss      # Admin layout styles + sidebar
    _admin_dashboard_components.scss  # Admin-specific components (cards, tables)
  pages/
    _dash_home.scss           # Specialist dashboard page styles
    _dash_assignments.scss    # Assignment index styles
  utils/
    _variables.scss           # Shared color tokens + spacing scale (READ ONLY — admin module inherits, does not modify)
```

Admin module CSS lives in `layouts/_admin_dashboard.scss` and `layouts/_admin_dashboard_components.scss`. Page-specific styles go in `pages/_dash_admin_*.scss`. Never modify `_variables.scss` — that file is shared across all modules.

## Rails Implementation Conventions

All implementation must follow established Salus patterns. Deviations are not allowed.

### Naming & Schema Standards

| Pattern | Convention | Example |
|---------|------------|---------|
| Routes | Keyword args only, never positional | `admin_assignment_path(id: sp.id, locale: I18n.locale)` |
| Partials | Prefixed with `_`, snake_case | `_assignment_row.html.erb` |
| CSS classes | `dash-*` BEM, never raw Tailwind utility classes | `dash-group`, `dash-stat`, `dash-button--primary` |
| Controllers | Thin — business logic in models/POROs | Only `redirect_to`, `render`, `permit` |
| Models | Rich — scopes, validations, enum-style strings | `scope :active, -> { where(status: "active") }` |
| Parameters | `params.require(:resource).permit(:field1, :field2)` | Only actual db columns |
| Redirects | `redirect_to path(id: resource.id), notice: "..."` | Never inline flash hash |
| Enums | String columns with explicit `STATUSES = []` constant | Never integer enums |

### Consistent Patterns Across Modules

The admin module must mirror existing specialist module patterns exactly:

- **Layout:** `layout "admin_dashboard"` in `Admin::BaseController` — NOT `"application"`
- **Sidebar nav sections:** Dashboard, Specialists, Patients, Assignments, Referrals, Chat Health, Specialist Requests
- **Card pattern:** `<div class="dash-stat">` with `dash-stat__icon--*` for the icon container
- **Table rows:** `<div class="dash-group__row">` inside `<div class="dash-group__content">`
- **Filter chips:** `<a href="?filter=active" class="filter-chip <%= "active" if params[:filter] == "active" %>">`
- **Status badges:** `<span class="badge badge--success">` (not `--info`, `--warning` — match existing class names)
- **Form inputs:** Match existing form builder pattern if one exists; default to standard Rails `form_with`

### Ownership Per Module

| Module | Owner | CSS files | Layout file |
|--------|-------|-----------|-------------|
| `app/views/layouts/specialist_dashboard.html.erb` | Specialist module | `app/assets/stylesheets/layouts/_dashboard.scss` | `specialist_dashboard` |
| `app/views/layouts/admin_dashboard.html.erb` | Admin module | `app/assets/stylesheets/layouts/_admin_dashboard.scss` | `admin_dashboard` |
| `app/views/specialist/` | Specialist module | `app/assets/stylesheets/pages/_dash_home.scss` etc. | `specialist_dashboard` |
| `app/views/admin/` | Admin module | `_admin_dashboard.scss` | `admin_dashboard` |

No cross-module view ownership. Admin never styles specialist views, and vice versa.

### TDD Approach Per Unit

Every unit follows red-green-refactor. The test file is written **before** the implementation file.

**Unit test file order:** `spec/requests/admin/` → request specs (full HTTP stack)
**Model specs:** `spec/models/` for model-level logic (scopes, enums, validations)
**Service specs:** `spec/services/admin/` for service objects

Never write view specs (system/feature specs only for full-page flows).

### Critical Bug Fix Prerequisites

**Bug 1 (Unit 4, fix first):** `SpecialistRequest#approve!` must create `SpecialistPatient` on approval.
- Write failing test in `spec/models/specialist_request_spec.rb` first
- Fix the method, verify test passes
- This unblocks Unit 5's approval workflow testing

**Bug 2 (Unit 4, fix first):** `Specialist::MessagesController#create` has no authorization on `specialist_id`.
- Write failing test in `spec/requests/specialist/messages_controller_spec.rb` first
- Add `before_action :verify_specialist_relationship` — block forged `specialist_id`
- Verify test passes
- This unblocks Unit 6's chat health verification

### Migration Naming

Follow Rails convention: `YYYYMMDDHHMMSS_create_specialist_referral_clicks.rb`
Use `change` method (not `up`/`down`) with `add_reference` / `create_table`.

### Route Placement (Critical)

Public routes MUST be placed **before** `scope "(:locale)"` in `config/routes.rb`:
```ruby
# BEFORE scope "(:locale)"
get "/join/specialist/:hash", to: "public/join#specialist", as: :join_specialist
get "/specialist/register", to: "public/specialist_registrations#new", as: :specialist_register

scope "(:locale)" do
  # admin, specialist, patient namespaces — with locale prefix
end
```
Place admin routes inside the locale-scoped admin namespace. Public routes outside locale scope.

### Verify Before Committing

After each unit lands, run:
```bash
mise exec -- bundle exec rails routes | grep admin
mise exec -- bundle exec rspec spec/requests/admin/ --format progress
```
All admin request specs must pass. No regressions in existing specialist/patient specs.

## Open Questions

### Resolved During Planning

- **Referral URL uniqueness:** Use `SpecialistRequest#hash_code` (already exists, returns first UUID segment uppercase). Route: `/join/specialist/:hash` maps to a public controller that looks up the request by hash_code.
- **Pre-assignment flow:** Patient visits `/join/specialist/:hash` → sees specialist info + "Request to join" button → creates `SpecialistPatient` with `status: "pending"` → admin approves in assignment command center → status becomes `"active"`
- **QR code generation:** Use `RQRCode` gem to generate QR code image from the referral URL. Display alongside the URL in admin UI.
- **"No specialist" banner placement:** Render in the patient messages view (`app/views/specialist/messages/index.html.erb`) when `@no_specialist_assigned` is true. Use existing flash/alert mechanism.
- **Bug fixes dependency:** The messaging authorization bug and the approve! bug must be fixed as prerequisites before testing the no-specialist banner and self-registration flows.

### Deferred to Implementation

- Whether to use a background job for referral click tracking (defer until analytics volume is known)
- Exact threshold for "capacity warning" on specialist load (defer — no capacity model exists yet)

## Output Structure

    app/
      controllers/
        admin/
          assignments_controller.rb        # Unit 2: assignment management
          referrals_controller.rb          # Unit 3: referral URL management + analytics
          specialist_requests_controller.rb # Unit 5: extend existing with self-registration form
        public/
          join_controller.rb              # Unit 3: /join/specialist/:hash route
        patient/
          messages_controller.rb          # Unit 4: add no-specialist guard
      models/
        specialist_referral_click.rb      # Unit 3: track URL clicks
        specialist_request.rb             # Bug fix: approve! creates SpecialistPatient
        specialist_patient.rb            # Add scope: :unassigned
      views/
        admin/
          assignments/
            index.html.erb               # Unit 2
          referrals/
            index.html.erb               # Unit 3: referral analytics
          specialists/
            index.html.erb               # Unit 1: specialist list with URL + QR
            show.html.erb                # Unit 1
          shared/
            _admin_layout.html.erb       # Unit 1: extracted layout partial
          dashboard/
            index.html.erb                # Unit 1: command center cards
          specialist_requests/
            index.html.erb                # Unit 5: vetting queue
            new.html.erb                 # Unit 5: self-registration form
        public/
          join/
            specialist.html.erb           # Unit 3: pre-assignment landing page
        layouts/
          admin_dashboard.html.erb        # Unit 1: new admin layout
        specialist/
          messages/
            index.html.erb                # Unit 4: add no-specialist banner
      services/
        admin/
          chat_health_service.rb          # Unit 6: aggregate chat metrics
      assets/
        stylesheets/
          layouts/
            _admin_dashboard.scss        # Unit 1: admin-specific styles
            _admin_dashboard_components.scss # Unit 1: admin card styles
    db/
      migrate/
        YYYYMMDDHHMMSS_create_specialist_referral_clicks.rb
        YYYYMMDDHHMMSS_add_approved_at_to_specialist_requests.rb  # Track approval time
        YYYYMMDDHHMMSS_add_referral_url_to_specialists.rb        # URL slug field

## Implementation Units

### Phase 1: Foundation

- [x] **Unit 1: Admin Layout + Command Center Dashboard** — COMPLETED

**Goal:** Give the admin module a proper layout and transform the existing passive stats dashboard into an actionable command center.

**Requirements:** R1

**Dependencies:** None

**Files:**
- Create: `app/views/layouts/admin_dashboard.html.erb`
- Create: `app/assets/stylesheets/layouts/_admin_dashboard.scss`
- Create: `app/assets/stylesheets/layouts/_admin_dashboard_components.scss`
- Modify: `app/controllers/admin/base_controller.rb` — change `layout` from application to `"admin_dashboard"`
- Modify: `app/views/admin/dashboard/index.html.erb` — replace stats cards with actionable command center cards
- Create: `spec/requests/admin/dashboard_controller_spec.rb` — (extend existing minimal spec if one exists, otherwise create)

**TDD order:**
1. Write `spec/requests/admin/dashboard_controller_spec.rb` — test that dashboard shows 5 actionable stat cards with correct counts and links
2. Write `spec/requests/admin/dashboard_spec.rb` system test — admin logs in, lands on dashboard, sees cards with links
3. Create `_admin_dashboard.scss` with CSS variables matching specialist dashboard token set
4. Create `admin_dashboard.html.erb` layout — mirror `specialist_dashboard.html.erb` structure (sidebar + header + content)
5. Modify `Admin::BaseController` to use `layout "admin_dashboard"`
6. Modify `admin/dashboard/index.html.erb` — wire up stat cards with real count queries

**Admin layout pattern (mirror specialist dashboard):**
```erb
<%# app/views/layouts/admin_dashboard.html.erb %>
<div class="dash-home">
  <aside class="dash-home__sidebar">
    <nav class="dash-sidebar-nav">
      <%= link_to "Dashboard", admin_dashboard_path, class: "dash-sidebar-nav__item" %>
      <%= link_to "Specialists", admin_specialists_path, class: "dash-sidebar-nav__item" %>
      <%= link_to "Assignments", admin_assignments_path, class: "dash-sidebar-nav__item" %>
      <%# ... more nav items ... %>
    </nav>
  </aside>
  <div class="dash-home__main">
    <header class="dash-header">
      <h1 class="dash-header__title"><%= yield(:page_title) || "Admin" %></h1>
    </header>
    <main class="dash-home__content">
      <%= yield %>
    </main>
  </div>
</div>
```

**Dashboard stat card pattern (from specialist dashboard):**
```erb
<%# admin/dashboard/index.html.erb %>
<div class="dash-home">
  <div class="dash-group">
    <div class="dash-group__header">
      <h2 class="dash-group__title">Command Center</h2>
    </div>
    <div class="dash-group__content">
      <%# Stat cards in a grid %>
      <div class="dash-stat">
        <div class="dash-stat__icon dash-stat__icon--users"></div>
        <div class="dash-stat__body">
          <span class="dash-stat__number"><%= @unassigned_count %></span>
          <span class="dash-stat__label">Patients Unassigned</span>
          <%= link_to "Manage", admin_assignments_path(filter: "unassigned"), class: "dash-stat__link" %>
        </div>
      </div>
      <%# ... more cards ... %>
    </div>
  </div>
</div>
```

**CSS structure for admin layout:**
```scss
// _admin_dashboard.scss — layout shell
.dash-home { display: flex; min-height: 100vh; }
.dash-home__sidebar { width: 260px; flex-shrink: 0; background: var(--bg-header); }
.dash-home__main { flex: 1; display: flex; flex-direction: column; overflow: hidden; }
.dash-home__content { flex: 1; padding: var(--spacer); overflow-y: auto; }

// _admin_dashboard_components.scss — components
.dash-stat { background: var(--color-surface); border-radius: var(--radius); padding: 20px; border-top: 3px solid var(--color-primary); }
.dash-stat__number { font-size: 32px; font-weight: 800; display: block; }
.dash-stat__label { font-size: 11px; text-transform: uppercase; letter-spacing: 0.8px; color: var(--text-secondary); }
.dash-stat__link { font-size: 12px; color: var(--color-primary); margin-top: 4px; display: block; }
```

**Test scenarios:**
- Happy path: Admin logs in → lands on dashboard → sees all 5 command center cards with correct counts
- Happy path: Each card's number links to its management surface
- Edge case: Zero unassigned patients → card shows "0" with no alert styling
- Edge case: Admin unauthenticated → redirects to admin sign in

**Verification:**
- Admin layout renders with sidebar nav, header, content area
- Dashboard shows all 5 command center cards
- Each card number is clickable and navigates to correct page

**Status:** ✅ COMPLETED (2026-04-25)

---

### Phase 2: Core Assignment Management

- [x] **Unit 2: Patient-Specialist Assignment Command Center** — COMPLETED

**Goal:** Give admins a UI to view, filter, and manage all specialist-patient assignment relationships.

**Requirements:** R2, R3

**Dependencies:** Unit 1 (admin layout)

**Files:**
- Create: `app/controllers/admin/assignments_controller.rb`
- Create: `app/views/admin/assignments/index.html.erb`
- Create: `app/views/admin/assignments/_assignment_row.html.erb`
- Create: `spec/requests/admin/assignments_controller_spec.rb`
- Modify: `app/models/specialist_patient.rb` — add `scope :unassigned` and class method `orphaned_accounts`
- Modify: `config/routes.rb` — add `namespace :admin do resources :assignments`

**Approach:**
`Admin::AssignmentsController#index` renders a filterable table of all `SpecialistPatient` records with: patient name, specialist name, relationship_type badge, status badge, assigned date, actions (reassign, remove). Filters: all / active / pending / inactive / unassigned.

"Unassigned" is patients with no `SpecialistPatient` record at all — query via `Account.left_outer_joins(:specialist_patients).where(specialist_patients: { id: nil })`.

Bulk reassign: checkboxes on rows → "Reassign Selected" button → modal to pick target specialist → PATCH to `admin_assignments_path` with `assignment_ids: [...]` and `specialist_id: new_specialist_id`.

Single reassign: row action "Reassign" → same modal → submits to `admin_assignment_path(id: sp.id)` PATCH.

**Patterns to follow:**
- Specialist dashboard table: `dash-group__content` with `patient-list-item` rows
- Filter chips: `<a href="?filter=active" class="filter-chip <%= "active" if params[:filter] == "active" %>">`
- Route helpers: `admin_assignments_path`, `admin_assignment_path(id: sp.id)`

**Test scenarios:**
- Happy path: Admin visits assignments index → sees paginated table of all assignments
- Happy path: Filter by "unassigned" → shows patients with no specialist
- Happy path: Filter by specialist → shows only that specialist's patients
- Happy path: Single reassign → modal appears → pick specialist → submit → SpecialistPatient updated
- Edge case: Reassign to same specialist → no-op, no error
- Edge case: Empty table → shows empty state "No assignments found"
- Error path: Bulk reassign with no specialist selected → validation error on modal

**Verification:**
- Assignments index renders with filterable, sortable table
- Unassigned patients appear in the unassigned filter view
- Single and bulk reassign operations persist correctly

---

### Phase 3: Referral URL System

- [x] **Unit 3: Specialist Referral URL System with Analytics** — COMPLETED

**Goal:** Auto-generate unique referral URLs per specialist, display in admin management view, track clicks and conversions, and create the public join flow.

**Requirements:** R4, R5

**Dependencies:** Unit 1 (admin layout)

**Files:**
- Create: `db/migrate/YYYYMMDDHHMMSS_create_specialist_referral_clicks.rb`
- Create: `app/models/specialist_referral_click.rb`
- Create: `app/controllers/public/join_controller.rb`
- Create: `app/views/public/join/specialist.html.erb`
- Create: `app/views/admin/referrals/index.html.erb` (analytics dashboard)
- Modify: `app/views/admin/specialists/index.html.erb` — add referral URL + QR code column
- Modify: `config/routes.rb` — add `get "/join/specialist/:hash", to: "public/join#specialist", as: :join_specialist`
- Create: `spec/models/specialist_referral_click_spec.rb`
- Create: `spec/requests/public/join_controller_spec.rb`
- Create: `spec/requests/admin/referrals_controller_spec.rb`

**Approach:**
`SpecialistReferralClick` model: `specialist_request_id` (FK), `clicked_at`, `ip_address`, `user_agent`. Created when the public join URL is visited (before authentication).

Admin referrals index: table per specialist showing — specialist name, referral URL, total clicks (last 30 days), registrations started, registrations completed, conversion rate (completed/clicks). QR code generated via `RQRCode` gem, displayed as inline SVG.

Public join page (`/join/specialist/:hash`): Shows specialist's name, specialization, "Request to join as patient" button. Clicking creates a `SpecialistPatient` with `status: "pending"` and `relationship_type: "primary_care"`. Patient must be logged in or redirected to register first.

**Patterns followed:**
- QR code: inline SVG generated by `qr.as_svg(offset: 0, module_size: 3, view_box: true).html_safe`
- Analytics dashboard: same table pattern as assignments index
- Routes: `get "/join/specialist/:hash"` in the public scope (before `scope "(:locale)"`)

**Test scenarios:**
- Happy path: Admin referrals index shows per-specialist click/registration/conversion data
- Happy path: Public visits `/join/specialist/HASH` → sees specialist info → clicks "Request to join" → redirected to sign in if not logged in
- Happy path: Logged-in patient clicks "Request to join" → creates pending SpecialistPatient → shown confirmation
- Edge case: Invalid hash → 404 page
- Edge case: Patient already has active assignment to this specialist → shown "Already associated" message instead of button
- Edge case: Specialist request not found for hash → 404
- Error path: Duplicate SpecialistPatient creation → prevented by uniqueness constraint on (account_id, specialist_request_id)

**Verification:**
- Referral URL analytics dashboard renders per-specialist stats
- Public join URL resolves correctly for a valid hash
- QR code renders as inline SVG
- Clicking "Request to join" creates pending SpecialistPatient

---

### Phase 4: Orphan Detection + Patient Messaging Guard

- [x] **Unit 4: Orphaned Patient Detection + No-Specialist Messaging** — COMPLETED

**Goal:** Detect patients with no active specialist (orphaned) and show them in the admin command center, and add a patient-side banner blocking compose when no specialist is assigned.

**Requirements:** R3, R6

**Dependencies:** Unit 2 (orphan detection query)

**Files:**
- Modify: `app/models/specialist_patient.rb` — add `scope :orphaned` and class method
- Modify: `app/controllers/specialist_messages_controller.rb` — add authorization guard (`verify_specialist_relationship!`)
- Create: `spec/requests/specialist_messages_controller_spec.rb` — add authorization tests
- Modify: `app/views/admin/dashboard/index.html.erb` — add orphaned patient card (from Unit 1)

**Approach:**
Add to `SpecialistPatient`:
```ruby
scope :orphaned, -> {
  Account.where.not(id: active.select(:account_id))
}
```

Also add `SpecialistPatient.unassigned_accounts` as class method for the orphan query.

In `SpecialistMessagesController#create` — added `before_action :verify_specialist_relationship!` which checks `SpecialistPatient.active.exists?(account: current_account, specialist_id: params[:specialist_id])`. If not authorized, redirects back with alert.

**Patterns followed:**
- Banner partial: follow existing alert/notice pattern in views
- Authorization in controller: follow existing `before_action` pattern
- Redirect with alert: `redirect_to patient_messages_path, alert: "..."`

**Test scenarios:**
- Happy path: Patient with active specialist sends message → message created
- Happy path: Patient without specialist visits messages → "No Doctor Assigned" banner shown
- Edge case: Patient has pending (not active) specialist → treated as no specialist, banner shown
- Error path: Patient tries to forge specialist_id → 403 redirect with alert
- Edge case: Specialist was soft-deleted (future) → patient shows no specialist banner

**Verification:**
- Patient without specialist sees no-specialist banner in messages view
- Patient with active specialist sees normal compose box
- Forged specialist_id is rejected with redirect

---

### Phase 5: Specialist Self-Registration

- [x] **Unit 5: Specialist Self-Registration with Structured Admin Approval** — COMPLETED

**Goal:** Allow specialists to submit a registration request via a form, which enters a vetting queue for admin one-click approval. Also fix the existing bug where approving a specialist request does not create a SpecialistPatient record.

**Requirements:** R8, R9

**Dependencies:** Unit 1 (admin layout)

**Files:**
- Create: `db/migrate/YYYYMMDDHHMMSS_add_referral_url_fields_to_specialist_requests.rb`
- Modify: `app/models/specialist_request.rb` — fix `approve!` to create SpecialistPatient, add fields for self-registration
- Modify: `app/controllers/admin/specialist_requests_controller.rb` — extend to show full vetting card
- Create: `app/views/admin/specialist_requests/index.html.erb` — vetting queue with compare view
- Create: `app/views/admin/specialist_requests/vetting_card.html.erb`
- Create: `app/views/public/specialist_requests/new.html.erb` — self-registration form
- Modify: `config/routes.rb` — add public specialist request registration route
- Create: `spec/requests/admin/specialist_requests_controller_spec.rb` — extend existing
- Create: `spec/requests/public/specialist_requests_controller_spec.rb` — new
- Modify: `spec/models/specialist_request_spec.rb` — test approve! creates SpecialistPatient

**Approach:**
Public registration form at `/specialist/register` (public route, not admin): fields — email, password, first_name, last_name, specialization, field_of_expertise, specialization_description, license_number (optional). Creates `User` + `Specialist` + `SpecialistRequest` all in `pending` state.

Admin vetting queue (`Admin::SpecialistRequestsController` — extend existing): index shows all pending requests as "vetting cards" — applicant info, submitted fields, submitted at, days pending. Click into show → full comparison with standard template (highlights missing fields in amber, unexpected values in red). Approve button → `approve!` (fixed to create SpecialistPatient). Reject button → with reason field.

Bug fix: `SpecialistRequest#approve!` must:
```ruby
def approve!
  update!(status: "approved", approved_at: Time.current)
  SpecialistPatient.create!(
    specialist: specialist,
    account: specialist.user.account,  # the specialist's account IS the patient in this flow... wait
    status: "active",
    relationship_type: "primary_care"
  )
end
```
Wait — the specialist is a User who has an Account. But the patient is a different Account. In the self-registration flow, the specialist registers THEMSELVES as a specialist. They don't need a SpecialistPatient — THEY are the specialist. Actually: `SpecialistRequest` is for a patient REQUESTING to be assigned to a specialist. The specialist self-registration is different — they register as a specialist. So `approve!` on a specialist self-registration should set the SpecialistRequest to approved AND activate the specialist's `specialist` record. NOT create a SpecialistPatient. Let me reconsider.

Actually re-reading the model: `SpecialistRequest` has `account_id` (the patient requesting) and `specialist_id` (the specialist). So it IS patient-requesting-specialist. The existing approval flow marks the request approved but never creates the SpecialistPatient linking patient to specialist. That's the bug.

For self-registration: a NEW route and form for specialists to register themselves (not via SpecialistRequest — they fill a form, admin approves, THEN their specialist account is activated).

So two separate things:
1. Fix `SpecialistRequest#approve!` bug (patient requests to be linked to existing specialist) → creates SpecialistPatient
2. New specialist self-registration (new person registers AS a specialist) → different flow

The self-registration flow: `Public::SpecialistRegistrationsController` — create User + Specialist (inactive) + show "pending approval" message. Admin approves in vetting queue → Specialist becomes active.

**Patterns to follow:**
- Devise-style registration form: email, password, password_confirmation
- Admin approval redirect: `redirect_to admin_specialist_requests_path, notice: "..."`
- Reject with reason: `SpecialistRequest#reject!(reason:)` pattern

**Test scenarios:**
- Happy path: Specialist fills self-registration form → pending state → admin sees in vetting queue
- Happy path: Admin approves → specialist account activated → email notification (if mailer exists)
- Happy path: Admin rejects → specialist account not activated → rejection reason stored
- Happy path: Existing `SpecialistRequest#approve!` now creates SpecialistPatient (bug fix)
- Edge case: Duplicate specialist email → form shows validation error
- Edge case: Admin approves already-approved request → no-op
- Edge case: Specialist tries to register while pending → shown "already pending" message

**Verification:**
- Self-registration form creates pending specialist account
- Admin vetting queue shows pending registrations
- Approve creates SpecialistPatient and activates specialist
- Existing SpecialistRequest#approve! bug is fixed (verified by new test)

---

### Phase 6: Chat Health Monitor

- [x] **Unit 6: WhatsApp Chat Health Monitor** — COMPLETED

**Goal:** Give admins observability into the WhatsApp-style chat system — per-specialist message stats, delivery failures, zero-history patients, and ActionCable status.

**Requirements:** R7

**Dependencies:** Unit 1 (admin layout)

**Files:**
- Create: `app/services/admin/chat_health_service.rb`
- Create: `app/controllers/admin/chat_health_controller.rb`
- Create: `app/views/admin/chat_health/index.html.erb`
- Create: `app/views/admin/chat_health/_specialist_health_card.html.erb`
- Create: `spec/services/admin/chat_health_service_spec.rb`
- Create: `spec/requests/admin/chat_health_controller_spec.rb`

**Approach:**
`Admin::ChatHealthService` aggregates data per specialist:
- `messages_sent_last_30d`: count of SpecialistMessage where specialist is sender or recipient
- `messages_delivered`: messages where notifiable_type delivered (look at SpecialistNotification created)
- `delivery_failures`: SpecialistNotification of type `abnormal_measurement` or similar error types
- `avg_response_time_hours`: for each conversation, time between patient message and specialist response
- `zero_history_patients`: patients assigned to specialist with no SpecialistMessage records
- `last_message_at`: most recent message timestamp

Controller exposes these as `@specialist_health_stats` — array of hashes per specialist.

ActionCable status: check if `SpecialistMessagesChannel` has active connections via `ActionCable.server.connections`. Display as "Connected" / "Disconnected" indicator.

**Patterns to follow:**
- Service pattern: `Specialist::PatientReportService` as reference for service structure
- Stat card: `dash-stat` component from specialist dashboard
- Table with colored status indicators: `dash-group` with `badge badge--green/red`

**Test scenarios:**
- Happy path: Admin visits chat health → sees per-specialist cards with metrics
- Happy path: Specialist with healthy chat shows green status indicators
- Edge case: Specialist with 0 messages → shows "No chat history" in card
- Edge case: ActionCable disconnected → shows red "Disconnected" badge
- Error path: Service query fails → graceful error message in card, not broken page
- Integration: Verify aggregate numbers match sum of individual SpecialistMessage records

**Verification:**
- Chat health dashboard renders per-specialist stat cards
- Each card shows messages sent, delivery rate, response time, zero-history count
- ActionCable status indicator reflects actual connection state

---

## System-Wide Impact

- **Interaction graph:** New public routes added (`/join/specialist/:hash`, `/specialist/register`) — must be before locale scope in routes.rb
- **Error propagation:** ChatHealthService errors caught and displayed gracefully in dashboard cards — not propagated as 500s
- **State lifecycle risks:** Orphan detection query must handle patients who have NEVER had a specialist (no SpecialistPatient record) vs patients whose specialist was deactivated (SpecialistPatient exists but status != active)
- **API surface parity:** No new APIs — all admin-facing views, no external API changes
- **Integration coverage:** Assignment reassignment triggers `SpecialistPatient` update — verify via request spec that reassignment persists
- **Unchanged invariants:** Patient-side message sending flow unchanged except for authorization guard. SpecialistRequest existing approval flow pattern unchanged except approve! now creates SpecialistPatient (bug fix)

## Risks & Dependencies

| Risk | Mitigation |
|------|------------|
| Public join route conflicts with existing routes | Place `/join` and `/specialist/register` routes before the `scope "(:locale)"` in routes.rb |
| Referral click tracking creates write on every public page visit | Use `Rails.cache` for click counting or batch-insert clicks asynchronously — evaluate volume before production |
| Bulk reassign creates many SpecialistPatient updates | Use `update_all` for bulk, individual `create` for single |
| No specialist banner hides compose for all messages | Banner only shown when `@no_specialist_assigned` is true — normal patients unaffected |
| QR code generation adds latency to admin specialist index | Lazy-load QR codes, generate on demand in view |

## Documentation / Operational Notes

- Routes file: new public routes must be placed before `scope "(:locale)"` to avoid locale prefix matching
- `rake routes | grep "join\|specialist/register"` to verify new public routes are accessible
- Referral URL: the `hash_code` is derived from the SpecialistRequest's UUID — no collision with existing records since each request gets a UUID
- After deploying, run `rails db:migrate` for referral clicks table

## Sources & References

- **Origin document:** [docs/plans/2026-04-23-001-feat-specialist-dashboard-module-plan.md](docs/plans/2026-04-23-001-feat-specialist-dashboard-module-plan.md)
- Related code: `app/models/specialist_patient.rb`, `app/models/specialist_request.rb`, `app/controllers/specialist/messages_controller.rb`
- Related spec: `spec/requests/admin/specialist_requests_controller_spec.rb`
- CSS patterns: `app/assets/stylesheets/layouts/_dashboard.scss`, `app/assets/stylesheets/pages/_dash_home.scss`
