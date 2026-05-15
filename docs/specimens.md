# Test Specimens — Salus Admin Module

Named, reproducible test account constellations used across admin module specs. All specimens are built via `FactoryBot.create` using the factories defined in `spec/factories/`.

---

## Core Specimens

### :admin\_platform — Platform Administrator

The root admin for platform operations. Used when any spec needs a fully authenticated admin session without additional relationships.

```ruby
admin = create(:admin, email: "admin@salus.health")
# AdminUser(id: uuid, email: "admin@salus.health")
```

Authentication stub pattern:
```ruby
allow_any_instance_of(Admin::BaseController).to receive(:authenticate_admin!).and_return(true)
allow_any_instance_of(Admin::BaseController).to receive(:admin_signed_in?).and_return(true)
allow_any_instance_of(Admin::BaseController).to receive(:current_admin).and_return(admin)
```

---

### :dr_chen — Active Specialist with Roster

An active specialist with three assigned patients in various states. The reference specialist for assignment and chat health specs.

```ruby
specialist_user = create(:user, :specialist, email: "dr.chen@salus.health")
# => User with specialist role, associated Specialist record
#   specialist.specialization: "Cardiology"
#   specialist.field_of_expertise: "Heart Failure"

patient_A = create(:account, first_name: "Alice", last_name: "Morrow")
patient_B = create(:account, first_name: "Bob", last_name: "Hansen")
patient_C = create(:account, first_name: "Clara", last_name: "Diaz")

create(:specialist_patient, specialist: specialist_user, account: patient_A, status: "active")
create(:specialist_patient, specialist: specialist_user, account: patient_B, status: "active")
create(:specialist_patient, specialist: specialist_user, account: patient_C, status: "pending")
```

Full entity chain: `admin_platform` — (no relationship, admin operates independently)

---

### :dr_odelia — Specialist with Empty Roster

A newly approved specialist with zero patients assigned. Used to verify orphan detection and assignment prompts.

```ruby
specialist_user_2 = create(:user, :specialist, email: "dr.odelia@salus.health")
# specialist.specialization: "Endocrinology"
# No SpecialistPatient records
```

---

### :orphan_patient — Patient with No Specialist

A patient account with no specialist assignment — the "orphaned" state. Used to test unassigned count, orphan detection banner, and assignment flow.

```ruby
orphan = create(:account, first_name: "Orphan", last_name: "Patient")
# orphan has NO SpecialistPatient record
# orphan has NO SpecialistRequest
# Used to verify: unassigned count, orphan banner, assignment action
```

---

## Common Scenario Builders

### Scenario: Full Platform Snapshot

Admin sees specialists with varying roster states.

```ruby
def build_platform_snapshot
  admin = create(:admin)

  dr_chen = create(:user, :specialist, email: "dr.chen@salus.health")
  dr_odelia = create(:user, :specialist, email: "dr.odelia@salus.health")

  alice = create(:account, first_name: "Alice", last_name: "Morrow")
  bob = create(:account, first_name: "Bob", last_name: "Hansen")
  orphan = create(:account, first_name: "Orphan", last_name: "Patient")

  create(:specialist_patient, specialist: dr_chen, account: alice, status: "active")
  create(:specialist_patient, specialist: dr_chen, account: bob, status: "active")
  # orphan has no SpecialistPatient

  create(:specialist_request, account: create(:account), specialist: dr_chen, status: "pending")

  {
    admin: admin,
    specialists: [dr_chen, dr_odelia],
    patients: { alice: alice, bob: bob, orphan: orphan },
    pending_request_count: 1
  }
end
```

### Scenario: Pending Specialist Requests Queue

Specialist registration requests in various states for vetting UI tests.

```ruby
def build_requests_queue
  dr_chen = create(:user, :specialist)
  pending_req = create(:specialist_request, specialist: dr_chen, status: "pending")
  approved_req = create(:specialist_request, specialist: dr_chen, status: "approved")
  rejected_req = create(:specialist_request, specialist: dr_chen, status: "rejected")

  { pending: pending_req, approved: approved_req, rejected: rejected_req }
end
```

---

## Data Summary

| Specimen | Type | Relationships |
|---|---|---|
| `:admin_platform` | AdminUser | — |
| `:dr_chen` | User+Specialist | 2 active SpecialistPatients, 1 pending |
| `:dr_odelia` | User+Specialist | 0 SpecialistPatients |
| `:orphan_patient` | Account | 0 SpecialistPatients, 0 SpecialistRequests |

---

## Usage in Specs

```ruby
context "with an unassigned patient" do
  let(:orphan) { create(:account, first_name: "Orphan", last_name: "Patient") }

  it "shows unassigned count of 1" do
    get admin_dashboard_path
    expect(response.body).to include("1")
    expect(response.body).to include("Unassigned")
  end
end

context "with specialist requests" do
  let(:specialist) { create(:user, :specialist) }
  let!(:pending) { create(:specialist_request, specialist: specialist, status: "pending") }

  it "shows pending count" do
    get admin_dashboard_path
    expect(response.body).to include("1")
    expect(response.body).to include("Pending Requests")
  end
end
```