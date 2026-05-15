# Specialist (Doctor) Dashboard — UX Planning Brief

**Date:** 2026-04-23
**Feature:** Specialist Dashboard Module — patient monitoring, alerts, medication/treatment approvals
**User:** Specialist (doctor) monitoring ~10 chronic disease patients, multiple times per day

---

## 1. User Segments

| Segment | Role | Context |
|---|---|---|
| **Primary user** | Specialist / attending physician | Monitoring 8–15 chronic disease patients on Salus. Opens dashboard multiple times daily between appointments or at start/end of shift. Health literacy is high but time is tight. |
| **Secondary** | Administrative staff | May review patient lists but not act on clinical alerts. Not in scope for v1. |

**User constraints:**
- 5 minutes or less per patient on average
- Context-switching between patients and other work
- Moderate health literacy; no training on Salus needed
- High trust bar — clinical decisions require documentation

---

## 2. Core Journeys

### Journey 1: Morning Triage (Primary — Alert-Driven)

1. Doctor opens dashboard → sees prioritized alert queue
2. Highest-priority alert is surfaced: patient name, alert type, severity badge, time elapsed
3. Doctor clicks patient name or alert row → navigates to **Patient Detail View**
4. Doctor reviews patient context (measurement trends, adherence card, care history)
5. Doctor takes action: acknowledges alert, writes clinical note, sends recommendation, or schedules
6. Doctor marks alert resolved (with note/plan) → returns to dashboard → next alert in queue
7. Repeat until queue is clear or time runs out

### Journey 2: Mid-Day Check-In (Light)

1. Doctor opens dashboard between appointments
2. Glances at top-of-queue alerts only — if nothing new, closes
3. If a new alert fires (push notification or badge update), acts on it immediately

### Journey 3: Prescribing / Approving Medication or Treatment

1. Doctor receives alert: "Patient Alex requested medication: Metformin 500mg"
2. Doctor navigates to patient detail (via alert or patient list)
3. Reviews patient's current medications, measurement trends, and notes
4. Decides: approves (optionally modifying dosage), rejects with reason, or defers
5. Doctor writes a clinical note/plan (required text field before submit)
6. System notifies patient of the decision

### Journey 4: Requesting a Medication or Treatment (Doctor-Initiated)

1. Doctor opens patient detail (from list or alert)
2. Clicks "+ Medication" or "+ Treatment"
3. Fills form: name, dosage, frequency, notes
4. Writes clinical rationale (required text field)
5. Submits → notification sent to patient → appears in patient's "Recommendations" queue
6. Patient accepts or declines → system notifies doctor

### Journey 5: Ad-Hoc Patient Review

1. Doctor selects patient from searchable, filterable list
2. Patient detail opens — sees measurement trends, AI prediction card, care history timeline
3. Doctor may or may not take action; closes and returns to dashboard

---

## 3. Onboarding

**Assumption:** The doctor is already onboarded to Salus (authenticated, profile set up, patients assigned by admin).

The dashboard should create value on **first open** without any setup steps:
- If no patients assigned: empty state with clear message — "No patients assigned yet. Patients will appear here once added by your administrator."
- If patients assigned but no alerts: calm empty state — "All caught up. No alerts right now."
- Alert queue is never pre-populated with past alerts; only active, unacknowledged alerts appear.

**No onboarding flow is needed for v1.** The dashboard is purely operational.

---

## 4. Day-to-Day Workflow

### Entry Point
The dashboard is the doctor's **home base** — the URL they bookmark, the page they return to between tasks.

### What they see first
**Alert Queue** — prioritized list, highest severity at top. The queue never shows more than ~20 items at once. Doctors do not scroll through hundreds of alerts; if the queue is longer than 20, the oldest unacknowledged alerts are paginated or access is given to "View all".

### Queue Item Structure (each alert)
- Patient name + avatar
- Alert type badge (color-coded by severity: red/yellow/blue)
- Brief context line: e.g., "Adherence dropped to 62% — 4 missed doses this week"
- Time elapsed ("3 hours ago", "2 days ago")
- Status: "Needs attention" / "Pending" / "Resolved"
- Quick-action buttons: "View Patient" (primary), "Acknowledge" (secondary — marks acknowledged with optional note, does not resolve)

### Resolving an Alert
When "View Patient" is clicked → navigate to Patient Detail View. Doctor takes action, then marks the originating alert as resolved with a clinical note. The resolution note is required and persisted in the patient's care history.

### What prompts return visits
1. Browser push notification when a high-priority alert fires
2. Badge count on the dashboard tab ("3 alerts")
3. Patient chat message notification
4. End-of-day review habit (optional)

### Progress communication
- Alert queue count shown as badge on dashboard nav item
- Each patient row shows unread alert count as a small red badge
- Resolved alerts are removed from the main queue and logged in the patient's care history

### What happens when they skip / fall behind
- If > 24 hours pass without acknowledgment, a high-severity alert escalates (visual indicator changes from yellow to red, badge count increments)
- Doctors should not feel shame or pressure — the system surfaces, it does not judge

---

## 5. Engagement Strategy

### Do
- Surface only the most critical items. "All caught up" state should feel normal and good, not like a trick.
- Use time-elapsed labels ("3 hours ago") rather than timestamps — these are more scannable.
- Provide clear, actionable labels on every button — no generic "Submit" or "OK".
- Allow "Notify me again in..." as a first-class action on any alert — deferring is not ignoring.
- Preserve resolved alerts as clinical notes in the patient's care history — this is the doctor's legal record.

### Do not
- Use streaks, leaderboards, or gamification — this is clinical care, not a fitness app.
- Shame users for missed tasks or unresolved alerts — neutral presentation of state.
- Flood the queue with low-priority notifications — alert fatigue is a real risk. Only surface clinically relevant alerts.
- Send push notifications for routine events — only high-severity alerts and patient messages warrant interruption.

---

## 6. Accessibility and Inclusion

### Readability and plain language
- Alert labels use plain language: "Missed medication" not "MEDICATION_LOG_MISSED_EVENT"
- Clinical jargon is avoided in alert titles; detailed context appears in the patient detail view
- All text must be at least WCAG AA contrast compliant

### Visual design
- Color is never the only signal — every alert type has both a color badge AND an icon (e.g., red background + pill icon for missed medication)
- Alert queue alternates row backgrounds subtly (not purely decorative — aids scanning)
- Focus state is clearly visible on all interactive elements (keyboard navigation support required)

### Assistive technology
- All interactive elements are keyboard-navigable (`Tab`, `Enter`, `Escape`)
- Alert list uses semantic HTML (`<ul>`, `<li>`, proper heading hierarchy) — not `div` soup
- Screen reader: each alert row announces "Patient [Name], [Alert type], [Severity], [Time elapsed]"

### Cognitive load
- Maximum 3 actions visible per alert row (View, Acknowledge, Chat)
- No modal dialogs on the dashboard — actions navigate, never block
- Empty states are full and informative — never just "No alerts"

### Trust and safety
- Clinical notes are private to the doctor and patient — no other patients can see them
- Alert resolution notes are immutable once written — they form part of the medical record
- No auto-deletion of alerts or notes

---

## 7. Layout Strategy

### Overall Structure

```
┌─────────────────────────────────────────────────────┐
│  [Sidebar Nav]     MAIN CONTENT AREA               │
│  ─────────────     ─────────────────────────         │
│  Dashboard ●       ┌─── Alert Queue ─────────────┐  │
│  Patients          │  [Alert Row]                 │  │
│  Messages          │  [Alert Row]                 │  │
│  Schedules         │  [Alert Row]                 │  │
│  Notifications    │  ...                         │  │
│  Profile           │  [View all / pagination]     │  │
│                    └─────────────────────────────┘  │
│                    ┌─── At-a-Glance Stats ───────┐  │
│                    │  Patients: 10 | Alerts: 3   │  │
│                    └─────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
```

### Visual Pacing
- **Alert queue takes 60–70% of viewport width** — this is the primary workspace
- **Stats strip is minimal** — single line showing patients count + active alert count
- **Patient list is secondary** — accessible via sidebar nav or keyboard shortcut
- **Quick-action toolbar** is sticky at top of patient detail view only, not on the dashboard itself
- Plenty of whitespace around alert rows — breathing room reduces cognitive load

### Hierarchy of Information
1. **Alert queue** (top, dominant) — what needs attention *now*
2. **Patient name + primary disease** (within each alert row) — who
3. **Alert context line** — what happened
4. **Time elapsed** — when
5. **Patient list / search** — sidebar, accessible but not competing for attention
6. **Stats** — minimal, bottom of dashboard

### Dashboard States
- **Empty queue:** "All caught up. No alerts right now." with a subtle check icon, neutral tone
- **Low alert count (1–3):** Normal queue display
- **High alert count (4+):** Queue shows top 5 with "View all X alerts" at bottom
- **Connection error:** Banner at top with retry action, queue shows last known state from cache

### Patient Detail View Structure
```
┌─────────────────────────────────────────────────────┐
│  ← Back to Dashboard    [Patient Name]    [Message] │
│                         [Risk Badge] [AI Card]       │
├─────────────────────────────────────────────────────┤
│  [Measurement Trends Chart — 7d / 30d / 90d tabs]   │
├─────────────────────────────────────────────────────┤
│  [Care History Timeline — 30-day default]            │
├─────────────────────────────────────────────────────┤
│  [Pending Requests: Medications | Treatments]       │
│  [Medications Table]  [Treatments Table]             │
├─────────────────────────────────────────────────────┤
│  [Specialist Notes]    [Chat Thread]                 │
└─────────────────────────────────────────────────────┘
```

### Responsive Strategy
- **Desktop (primary):** Full two-column layout — alert queue left, patient detail right (slide-in panel)
- **Tablet (secondary):** Alert queue full width, patient detail as a new page (not slide-over)
- **Mobile (minimal):** Not a primary use case — but alert list should be readable; patient detail as new page

---

## 8. Key States

| State | What the user sees | What they feel |
|---|---|---|
| **Default (queue has items)** | Prioritized alert list, top item most urgent | Alerted, focused |
| **Empty queue** | "All caught up. No alerts right now." + check icon | Calm, reassured |
| **Patient detail (normal)** | Measurement chart, care history, medication list, notes | Informed, in control |
| **Patient detail (urgent alert active)** | Pulsing red alert badge on patient name; chart shows abnormal reading highlighted in red | Urgency without panic |
| **Medication approval form open** | Slide-over form: medication name, dosage, frequency, clinical note (required), approve/reject buttons | Clinical authority, deliberate |
| **Sending recommendation** | Form with required clinical rationale field; submit confirms "Sent to patient" | Purposeful |
| **Alert resolved** | Alert disappears from queue (logged to care history); toast: "Alert resolved. Note saved." | Accomplished |
| **Error — form validation fail** | Field-level inline errors: "Clinical note is required before submitting" | Clear, fixable |
| **Error — server fail** | Banner: "Something went wrong. Your changes were not saved. [Retry]" | Concerned but supported |
| **Loading (page transition)** | Skeleton rows on alert list; patient detail shows last cached data + loading spinner on new sections | Patient, not impatient |

---

## 9. Interaction Model

### Alert Queue → Patient Detail Flow
1. Doctor clicks alert row → Turbo navigation to `/specialist/patients/:id?alert_id=xxx`
2. Patient detail view opens with the originating alert highlighted
3. Doctor reviews context → takes action (approve, note, recommend)
4. Doctor marks alert resolved (button in alert banner at top of patient detail)
5. Resolution form: text field (required) + "Resolve & notify later" / "Resolve" buttons
6. On resolve → Turbo navigates back to dashboard with toast confirmation
7. Alert is removed from queue; note is persisted to care history

### No Double-Navigation Rule
- If a patient has 2 pending medication requests and 1 pending treatment request, all three are visible in the patient's detail view under their own sections — doctor resolves all in one place without returning to dashboard between each action.
- Dashboard is for triage only; patient detail is the action hub.

### Quick-Action Toolbar (on Patient Detail)
Sticky toolbar at top of patient detail view, always visible:
- `+ Note` — opens inline note form
- `+ Medication` — opens medication recommendation form
- `+ Treatment` — opens treatment recommendation form
- `Schedule` — links to schedule creation
- `Message` — opens chat thread

All pre-fill patient context. No toolbar on the dashboard itself — dashboard is read-only triage.

### Alert Acknowledgment vs. Resolution
- **Acknowledge:** Doctor has seen the alert but is not done acting. Alert stays in queue (dimmed) with "Acknowledged" label. Acknowledgment is optional and fast — one click or a keyboard shortcut (`A`).
- **Resolve:** Doctor has finished the clinical response. Alert is removed from queue. Resolution requires a clinical note (required text field). Resolved alerts are logged.

### "Notify Me Later" Flow
- Available on any alert row or patient detail
- Selects a time: 1 hour / 4 hours / 1 day / 3 days / 1 week
- System reschedules a reminder notification for the doctor
- Alert disappears from queue until the reminder time passes
- Patient is not notified of the deferral

---

## 10. Content Requirements

### Alert Labels and Copy
| Alert Type | Label (Plain Language) | Context Line Example |
|---|---|---|
| `sos_alert` | Emergency Alert | "Patient triggered SOS — immediate action required" |
| `missed_medication` | Missed Medication | "Missed 3 doses of Metformin this week" |
| `low_adherence` | Adherence Drop | "Adherence dropped to 62% — below your 80% threshold" |
| `abnormal_measurement` | Abnormal Reading | "Blood pressure 158/102 — flagged as hypertensive" |
| `new_message` | New Message | "New message from [Patient Name]" |
| `recommendation_response` | Recommendation Update | "[Patient] accepted your Metformin recommendation" |

### Empty State Messages
- **Alert queue empty:** "All caught up. No alerts right now." + subtle check icon
- **Patient list (no patients):** "No patients assigned yet. Patients will appear here once added by your administrator."
- **Patient detail (no medications):** "No medications recorded. Click '+ Medication' to add."
- **Patient detail (no care history):** "No care history yet. Events will appear here as they occur."
- **No pending medication requests:** "No pending requests."
- **No pending treatment requests:** "No pending requests."

### Error Messages
- **Form validation:** Field-level inline: "Clinical note is required before submitting."
- **Server error on submit:** "Something went wrong. Your changes were not saved. [Retry]"
- **Patient not found:** "Patient not found or you don't have access to this record."
- **FHIR import fail:** "Could not read FHIR file. Make sure it's a valid FHIR JSON bundle exported from a compatible system."

### Microcopy
- Button labels: specific and action-oriented — "Approve Medication Request", "Send Recommendation", "Resolve Alert"
- Never: "Submit", "OK", "Confirm" (too generic)
- Resolution note placeholder: "Describe the action taken or clinical rationale (required for record)"
- Alert defer label: "Remind me in..."

---

## 11. Recommended References

During implementation, these skills/patterns should be consulted:

- **Spatial layout** — `/impeccable` spatial-design.md for dashboard grid and alert queue spacing
- **Color system** — existing DaisyUI/Tailwind tokens; alert severity color mapping (red/yellow/blue) must be consistent with existing `notification_color` pattern in the codebase
- **Motion/transition** — slide-over panel animation for patient detail; subtle fade for queue item removal on resolve
- **Form design** — clinical note field with character guidance; required field indicators
- **Typography** — clear hierarchy: patient name (heading), alert type (badge), context (body), time (caption)
- **Toast/notification** — success confirmation after alert resolution
- **Empty states** — calm, reassuring, actionable empty states with clear next steps
- **Keyboard shortcuts** — j/k navigation for alert queue (vim-style or Bloomberg-style)

---

## 12. Open Questions for Implementation

| Question | Why It Matters | Resolution Owner |
|---|---|---|
| Should "Acknowledge" be a separate step from resolution, or merged? | Affects workflow design and data model. Current thinking: acknowledge is optional/fast; resolution is mandatory with note. | Product + Doctor input |
| What's the maximum alert queue size before pagination? | 20 items seems right but needs validation with real workflow | Doctor input |
| Do doctors want a desktop push notification for all alert types or only Critical? | Alert fatigue risk — only Critical + messages? | Doctor input |
| Should the "Notify me later" time picker have preset options or a custom datetime picker? | 1h / 4h / 1d / 3d / 1w presets are faster; custom is more flexible | Design decision |
| What's the minimum viable mobile experience? | Dashboard is desktop-primary; decide if mobile is "read-only" or "action-capable" | Product decision |
| Does the alert banner on patient detail persist until the alert is resolved, or dismissible? | Non-dismissible banner creates urgency but may feel aggressive | Doctor input |
| Should alert resolution notes be visible to patients? | Clinical record vs. patient transparency tradeoff | Product/legal decision |
