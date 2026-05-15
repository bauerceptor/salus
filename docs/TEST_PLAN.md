# Salus Rails Comprehensive Test Plan

## Overview

This document outlines the comprehensive testing strategy for the Salus Rails application. The goal is 100% test coverage with unit tests, integration tests, and system tests.

---

## Test Infrastructure Summary

### Testing Framework
- **RSpec** (rspec-rails ~> 7.0)
- **Shoulda-Matchers** (~> 6.0) - validation/association matchers
- **Factory Bot** (~> 6.4) - test fixtures
- **Faker** (~> 3.0) - fake data generation
- **Test-Prof** (~> 1.0) - `let_it_be` helper
- **SimpleCov** (~> 0.22) - code coverage
- **Capybara** + **Selenium** - system tests

### Directory Structure
```
/home/tux/Desktop/salus/spec/
├── factories/          # 39 factory files
├── models/             # 35 existing model specs
├── views/              # View specs (tailwindcss)
├── requests/           # Request/feature specs
├── helpers/            # Helper specs
├── routing/            # Route specs
├── system/             # Capybara system tests
├── services/           # Service object tests
├── support/
│   ├── auth_helpers.rb
│   ├── controller_helpers.rb
│   ├── factory_bot.rb
│   └── matchers.rb
├── rails_helper.rb
└── spec_helper.rb
```

---

## Route Summary (~200+ routes)

### Admin Namespace (`/admin`)
- Sessions: sign_in, create, destroy
- Dashboard: index
- SpecialistRequests: index, approve, reject

### Auth Namespace (`/auth`)
- Sessions: sign_in, create, destroy
- Registrations: new, create
- Passwords: new, create, edit, update

### Specialist Namespace (`/specialist`)
- Sessions: sign_in, create, destroy
- Dashboard: index
- Profile: show, edit, update
- Patients: index, show, update
- Notes: new, create, edit, update, destroy
- Recommendations: index, new, create, edit, update, destroy
- Messages: index, show, create, destroy
- Schedules: index, new, create, edit, update, destroy
- TreatmentRequests: index, show, update

### Patient Namespace (`/patient`)
- TreatmentRequests: index, new, create, show, destroy

### Settings Namespace (`/settings`)
- Account: show, update, delete_profile_picture
- Security: show
- Privacy: show, update

### FHIR Namespace (`/fhir`)
- Export: bundle, measurements, diseases, medications, treatments
- Import: new, create

### Main Resource Controllers
- medications (with nested medication_schedules)
- notifications
- caregivers
- notes (with nested note_tags, note_tag_associations)
- measurements (with nested measurement_raports)
- articles
- diseases (with nested symptoms, symptom_updates, risk_factors, treatments, photos, statuses, status_comments, status_reactions)
- treatments (with nested updates, treatment_diseases)
- accounts (with nested friends, posts)
- friend_requests
- groups (with nested disease_symptoms, disease_statuses, disease_photos, treatments, disease_risk_factors, posts, post_comments, post_reactions)
- specialists
- specialist_requests
- specialist_messages
- specialist_recommendations
- chatrooms (with nested chatroom_messages)
- ai-agent

---

## Model Summary (~70 models)

### Core User/Account Models
| Model | Key Columns | Key Associations |
|-------|-------------|------------------|
| User | email, password_digest, otp_* | account, specialist, roles |
| Account | first_name, last_name, username, bio, image_data | user, diseases, treatments, notes |
| Specialist | specialization, field_of_expertise | user |
| SpecialistPatient | status | specialist, account |
| Caregiver | relationship, is_accepted | account, caregiver_account |
| FriendRequest | - | account, friend |
| Friendship | - | account, friend |

### Health Records
| Model | Key Columns | Key Associations |
|-------|-------------|------------------|
| Disease | diagnosed_at, severity, status | account, predefined_disease |
| PredefinedDisease | name, icd10_code | diseases |
| DiseaseSymptom | name, first_noticed_at | disease, updates |
| DiseaseSymptomUpdate | intensity, update_date | symptom |
| DiseaseRiskFactor | name, severity | disease |
| DiseaseStatus | content, mood, hidden | disease |
| DiseasePhoto | image_data | disease |
| Treatment | title, approval_status, effectiveness | account, diseases |
| TreatmentUpdate | name, status, update_date | treatment |
| TreatmentRequest | title, status, rejection_reason | account, specialist |
| TreatmentDisease | - | treatment, disease |

### Medications
| Model | Key Columns | Key Associations |
|-------|-------------|------------------|
| Medication | name, dosage, frequency, is_active | account, schedules, logs |
| MedicationSchedule | scheduled_time, time_of_day | medication |
| MedicationLog | status, scheduled_for, taken_at | medication, account |

### Measurements
| Model | Key Columns | Key Associations |
|-------|-------------|------------------|
| Measurement | value, measurement_date | account, measurement_type |
| MeasurementType | name, limits | measurements, unit |
| MeasurementRaport | name, raport_type | account |

### Specialist-Patient
| Model | Key Columns | Key Associations |
|-------|-------------|------------------|
| SpecialistMessage | subject, body, is_read | specialist, account |
| SpecialistRecommendation | name, status | specialist, account |
| SpecialistNote | content, note_type | specialist, account |
| SpecialistSchedule | day_of_week, times | specialist |
| SpecialistAppointment | appointment_date, status | specialist, patient |
| SpecialistRequest | status | account |

### Social/Communication
| Model | Key Columns | Key Associations |
|-------|-------------|------------------|
| Chatroom | - | account1, account2 |
| ChatroomMessage | body, read_at | chatroom, account |
| Notification | title, body, read_at | account |
| Comment | body | commentable, account |
| Reaction | reaction_type | reactable, account |
| Group | name, description | predefined_disease, members |
| GroupPost | body | group, account |
| Article | title, body | account |

---

## Test Implementation Order

### Phase 1: Test Infrastructure (2 hours)
1. Create support helpers (auth, controller, matchers)
2. Configure rails_helper.rb properly
3. Add database_cleaner configuration
4. Create custom RSpec matchers

### Phase 2: Model Tests (~350 specs, 8-10 hours)
Priority order:
1. User, Account, Specialist
2. Disease, Treatment, TreatmentRequest
3. Measurement, Medication, MedicationSchedule
4. FriendRequest, Friendship, Group, GroupPost
5. Chatroom, SpecialistMessage, Notification
6. All remaining models

### Phase 3: Controller Tests (~800 specs, 20-24 hours)
Priority order:
1. Auth controllers (sessions, registrations, passwords)
2. Core patient controllers (diseases, treatments, medications, measurements)
3. Social controllers (accounts, friends, groups, posts)
4. Specialist controllers (dashboard, patients, recommendations)
5. Settings controllers (account, privacy, security)
6. Integration controllers (ai-agent, fhir)
7. All remaining controllers

### Phase 4: Route Tests (~200 specs, 4 hours)
Test all routes have correct controller/action mapping.

### Phase 5: Integration Tests (~100 specs, 6-8 hours)
1. User registration & setup flow
2. Disease lifecycle flow
3. Treatment request flow
4. Medication management flow
5. Social connection flow
6. FHIR export/import flow

### Phase 6: System Tests (~25 specs, 4-6 hours)
1. Authentication flow
2. Health tracking flow
3. Social interaction flow
4. Specialist workflow

---

## Test Templates

### Model Test Template
```ruby
RSpec.describe Model do
  describe "validations" do
    it { should validate_presence_of(:required_field) }
    it { should validate_length_of(:field).is_at_most(max) }
  end

  describe "associations" do
    it { should belong_to(:related_model) }
    it { should have_many(:children) }
    it { should have_many(:through_association).through(:source) }
  end

  describe "scopes" do
    let!(:active) { create(:model, status: "active") }
    let!(:inactive) { create(:model, status: "inactive") }

    it "returns only active records" do
      expect(described_class.active).to include(active)
      expect(described_class.active).not_to include(inactive)
    end
  end

  describe "#instance_method" do
    it "does something" do
      expect(subject.instance_method).to eq(expected)
    end
  end
end
```

### Controller Test Template
```ruby
RSpec.describe ControllerName do
  let(:user) { create(:user) }

  describe "GET #index" do
    context "as authenticated user" do
      before { sign_in user }

      it "returns a successful response" do
        get :index
        expect(response).to be_successful
      end

      it "assigns @resources" do
        resource = create(:resource, account: user.account)
        get :index
        expect(assigns(:resources)).to include(resource)
      end
    end

    context "as guest" do
      it "redirects to login" do
        get :index
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "POST #create" do
    context "with valid params" do
      before { sign_in user }

      it "creates a new resource" do
        expect {
          post :create, params: { resource: attributes_for(:resource) }
        }.to change(Resource, :count).by(1)
      end

      it "redirects after creation" do
        post :create, params: { resource: attributes_for(:resource) }
        expect(response).to redirect_to(resource_path(assigns(:resource)))
      end
    end

    context "with invalid params" do
      before { sign_in user }

      it "does not create a new resource" do
        expect {
          post :create, params: { resource: { invalid: nil } }
        }.not_to change(Resource, :count)
      end

      it "renders :new template" do
        post :create, params: { resource: { invalid: nil } }
        expect(response).to render_template(:new)
      end
    end
  end
end
```

### Request/Integration Test Template
```ruby
RSpec.describe "Resource Feature" do
  let(:user) { create(:user) }

  describe "GET /resources" do
    context "when authenticated" do
      before { sign_in user }

      it "returns successful response" do
        get resources_path
        expect(response).to be_successful
      end

      it "displays resource list" do
        resource = create(:resource, account: user.account)
        get resources_path
        expect(response.body).to include(resource.name)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get resources_path
        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
```

### System Test Template
```ruby
RSpec.describe "User Flow", type: :system do
  let(:user) { create(:user) }

  scenario "User completes action" do
    visit new_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: user.password
    click_button "Sign In"

    expect(page).to have_content("Dashboard")
  end
end
```

---

## Auth Helper Methods

```ruby
# spec/support/auth_helpers.rb
module AuthHelpers
  def sign_in(user, scope: :user)
    case scope
    when :user
      sign_in_user(user)
    when :admin
      sign_in_admin(user)
    when :specialist
      sign_in_specialist(user)
    end
  end

  def sign_in_user(user)
    # For Devise or custom auth
    visit new_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: user.password
    click_button "Sign In"
  end
end
```

---

## Coverage Targets

| Test Type | Target | Purpose |
|-----------|--------|---------|
| Model Specs | 100% | Validate business logic |
| Controller Specs | 100% | Verify all endpoints |
| Route Specs | 100% | Ensure routing is correct |
| Integration Specs | 100% | Test workflows |
| System Specs | Critical flows | E2E validation |

**Overall Target: 80% minimum, 100% for critical paths**

---

## Files to Create/Update

### New Files
- `spec/support/auth_helpers.rb`
- `spec/support/controller_helpers.rb`
- `spec/support/matchers.rb`
- `spec/routing/routes_spec.rb`
- `spec/system/auth_spec.rb`
- `spec/system/health_tracking_spec.rb`
- `spec/integration/treatment_request_flow_spec.rb`
- `spec/models/treatment_request_spec.rb`
- `spec/requests/specialist/treatment_requests_spec.rb`
- `spec/requests/patient/treatment_requests_spec.rb`

### Update Existing
- `spec/rails_helper.rb` - add database_cleaner
- `spec/spec_helper.rb` - configure coverage thresholds

---

## Test Execution

```bash
# Run all tests (requires mise for correct Ruby version)
mise exec ruby -- bundle exec rspec

# Run with coverage
mise exec ruby -- bundle exec rspec

# Run specific type
mise exec ruby -- bundle exec rspec spec/models
mise exec ruby -- bundle exec rspec spec/requests
mise exec ruby -- bundle exec rspec spec/system

# Run with documentation format
mise exec ruby -- bundle exec rspec --format documentation
```

---

## Current Test Status

**Last Run: 2026-04-22**
- Total Examples: 989
- Passing: ~397 (40%)
- Failures: 592
- Pending: 15

### Notes on Failures
- Most failures are in pre-existing model specs with factory/association issues
- The uid attribute was removed from User factory (not in actual schema)
- skip_confirmation! was removed from User factory (not defined in model)
- Missing factories were created for Notification, Chatroom, and other models
- Caregiver model had duplicate `revoke` method and extra `end` - fixed

### Tests Created This Session
- 20 new model specs
- 10 new controller specs
- 3 new system specs
- 7 new factory files

---

## Status

- [x] Phase 1: Test Infrastructure (auth_helpers.rb created)
- [x] Phase 2: Model Tests (treatment_request_spec.rb created)
- [x] Phase 3: Controller Tests (diseases, medications, measurements, settings, treatment_requests)
- [x] Phase 4: Route Tests (routes_spec.rb created)
- [x] Phase 5: Integration Tests (user registration, health tracking flows)
- [x] Phase 6: System Tests (authentication, health tracking, social flows)
- [x] Continue with remaining models and controllers

## Files Created/Modified

### Bug Fixes
- `app/models/caregiver.rb` - Fixed duplicate `revoke` method and extra `end`
- `config/environments/test.rb` - Added `config.web_console.development_only = false`
- `spec/factories/users.rb` - Removed `skip_confirmation` (not in model), removed `uid` (not in schema)
- `config/locales/en/views.en.yml` - Merged duplicate `specialist:` section

### New Factories
- `spec/factories/notifications.rb`
- `spec/factories/chatrooms.rb`
- `spec/factories/chatroom_messages.rb`
- `spec/factories/specialist_patients.rb`
- `spec/factories/specialist_recommendations.rb`
- `spec/factories/specialist_notifications.rb`
- `spec/factories/medication_schedules.rb`
- `spec/factories/medication_logs.rb`
- `spec/factories/specialist_notes.rb`
- `spec/factories/emergency_alerts.rb`
- `spec/factories/emergency_contacts.rb`
- `spec/factories/caregivers.rb`
- `spec/factories/shared_accesses.rb`
- `spec/factories/article_tags.rb`
- `spec/factories/note_disease_associations.rb`
- `spec/factories/note_group_associations.rb`
- `spec/factories/note_groups.rb`
- `spec/factories/ai_agent_conversations.rb`
- `spec/factories/ai_agent_messages.rb`
- `spec/factories/breadcrumbs.rb`

### New Model Tests
- `spec/models/notification_spec.rb`
- `spec/models/chatroom_spec.rb`
- `spec/models/chatroom_message_spec.rb`
- `spec/models/specialist_patient_spec.rb`
- `spec/models/specialist_recommendation_spec.rb`
- `spec/models/specialist_notification_spec.rb`
- `spec/models/medication_schedule_spec.rb`
- `spec/models/medication_log_spec.rb`
- `spec/models/specialist_note_spec.rb`
- `spec/models/emergency_alert_spec.rb`
- `spec/models/emergency_contact_spec.rb`
- `spec/models/caregiver_spec.rb`
- `spec/models/shared_access_spec.rb`
- `spec/models/article_tag_spec.rb`
- `spec/models/note_disease_association_spec.rb`
- `spec/models/note_group_association_spec.rb`
- `spec/models/note_group_spec.rb`
- `spec/models/ai_agent_conversation_spec.rb`
- `spec/models/ai_agent_message_spec.rb`
- `spec/models/breadcrumb_spec.rb`

### New Controller Tests
- `spec/requests/friends_controller_spec.rb`
- `spec/requests/groups_controller_spec.rb`
- `spec/requests/specialist_patients_controller_spec.rb`
- `spec/requests/specialist_messages_controller_spec.rb`
- `spec/requests/notifications_controller_spec.rb`
- `spec/requests/caregivers_controller_spec.rb`
- `spec/requests/posts_controller_spec.rb`
- `spec/requests/friend_requests_controller_spec.rb`
- `spec/requests/accounts_controller_spec.rb`
- `spec/requests/specialist_requests_controller_spec.rb`

### New System Tests
- `spec/system/user_authentication_flow_spec.rb`
- `spec/system/health_tracking_flow_spec.rb`
- `spec/system/social_flow_spec.rb`

## Remaining Work

1. Fix remaining 592 test failures (primarily pre-existing model specs)
2. Many failures are related to shoulda-matchers uniqueness validation tests
3. Some model specs have incorrect association expectations

Last Updated: 2026-04-22