# Social Features Enhancement Plan — Salus Rails 8

## Overview

Enhance the patient social experience by restructuring disease-group access, refining the posting system, and adding proper community features (reputation, bookmarks, moderation, specialist presence, cross-disease communities).

## Problem Frame

**Current State:**
- Patients can see ALL groups regardless of their diseases (limited to 6 liver diseases)
- Posts live on dashboard with confusing 5-click creation flow
- Two separate post systems (DiseaseStatus vs GroupPost) with unclear purpose
- Groups are bare-bones with no moderation, structure, or specialist presence
- No reputation/bookmark/poll functionality

**Target State:**
- Patients ONLY see groups for diseases they have (auto-created when admin adds a disease)
- Posts live in proper social feeds (group feed + friends feed), NOT dashboard
- Rich post types: text, link preview, image, poll, hashtag
- Quote-post for resharing with comment
- Save/bookmark posts
- Reputation/karma system with badges
- Patient profiles with activity history
- Group moderation (patient moderators, report system, pinned posts)
- Specialist presence in groups (verified badge, expert responses)
- Cross-disease communities (general wellness, newly diagnosed)
- Onboarding nudge when diagnosed with new disease

## Tech Stack

- **Backend**: Rails 8.1, PostgreSQL with pgvector
- **Frontend**: SCSS + DaisyUI 5
- **Background Jobs**: Solid Queue
- **Execution**: `mise exec --` for all Rails/Ruby commands
- **Testing**: RSpec with TDD-first approach

## Requirements Trace

- R1. Patients must only see/join groups corresponding to diseases they have
- R2. Admin can register new chronic diseases, auto-generating a group
- R3. Posts must NOT appear on dashboard — only in dedicated social feeds
- R4. Posts support: text, link preview, image upload, poll, hashtag
- R5. Quote-post: reshare any post with a comment
- R6. Save/bookmark any post for later reference
- R7. Reputation system: karma score + badge/flair based on helpful upvotes
- R8. Patient profiles: public-ish profile with conditions, posts, score, join date
- R9. Group moderation: patient moderators, report button, pinned announcements
- R10. Specialist presence: verified badge in groups, ability to pin expert responses
- R11. Cross-disease communities: general wellness, newly diagnosed groups
- R12. Onboarding nudge: prompt to join disease community when diagnosed

## Scope Boundaries

- **NOT implementing**: Follow system (friend system is sufficient)
- **NOT implementing**: Real-time chat in groups (existing chatrooms are separate)
- **NOT implementing**: Direct messages (existing chatrooms cover this)

### Deferred to Separate Tasks

- Real-time notifications for new posts (ActionCable integration) — future iteration
- Push notifications — future iteration

## Key Technical Decisions

1. **Group auto-creation**: `after_create` on `PredefinedDisease` creates a `Group` automatically
2. **Feed composition**: Union of (group posts from patient's groups) + (disease statuses from friends)
3. **Post type**: Single `Post` model with `post_type` enum (text, link, image, poll, quote)
4. **Polymorphic quotes**: Quote posts reference original post via `quoted_post_id` (polymorphic)
5. **Karma calculation**: `SUM(reaction_value)` where like=+1, love=+2, sad=+1, others=0
6. **Bookmark**: `Account` has_many `:bookmarked_posts, through: :post_bookmarks, source: :post`
7. **Group category**: `GroupCategory` enum (support, informational, advocacy, general)
8. **Moderator role**: `GroupMembership` has `role: [:member, :moderator, :admin]` enum
9. **Specialist presence**: `SpecialistPatient` determines if user is specialist for a patient; specialists can join groups they have patients in

## Implementation Units

### Phase 1: Disease-Group Access Control

- [x] **Unit 1.1: Remove hardcoded liver disease filter from groups** ✅

**Goal:** Groups show for ALL predefined diseases, not just liver-related

**Files:**
- Modify: `app/controllers/groups_controller.rb`
- Modify: `app/models/predefined_disease.rb`
- Modify: `spec/system/social_flow_spec.rb`
- Modify: `config/locales/en/groups.en.yml`

**Approach:**
- Remove `.liver_related` scope from groups query
- All predefined diseases with `creates_group: true` get a group
- Update groups index to show all available groups

**Patterns to follow:**
- `GroupsController#index` pattern with Pagy
- Existing `.liver_related` scope removal

**Test scenarios:**
- Happy path: User sees groups for diseases they have in "Assigned" section
- Happy path: User sees available groups for diseases they don't have in "Available" section
- Edge case: User with no diseases sees no groups
- Edge case: PredefinedDisease without group (creates_group=false) not shown

---

- [x] **Unit 1.2: Admin disease registration with auto-group creation** ✅

**Goal:** When admin creates a new PredefinedDisease, a Group is auto-created

**Files:**
- Modify: `app/models/predefined_disease.rb`
- Modify: `db/migrate/XXXXXX_add_creates_group_to_predefined_diseases.rb`
- Create: `spec/models/predefined_disease_spec.rb`
- Modify: `config/locales/en/admin/predefined_diseases.en.yml`

**Approach:**
- Add `creates_group` boolean (default: true) to PredefinedDisease
- Add `after_create :create_group` callback
- Group name = disease name, description = "Community for [disease name] patients"

**Patterns to follow:**
- Existing `after_create :create_group` pattern already in PredefinedDisease for liver diseases
- Admin controller pattern from existing admin namespace

**Test scenarios:**
- Happy path: Creating PredefinedDisease auto-creates a Group
- Edge case: PredefinedDisease with creates_group=false does NOT create group
- Edge case: Duplicate group not created if already exists

---

- [x] **Unit 1.3: Add GroupCategory to groups** ✅

**Goal:** Classify groups by type

**Files:**
- Modify: `app/models/group.rb`
- Modify: `db/migrate/XXXXXX_add_category_to_groups.rb`
- Create: `spec/models/group_spec.rb` (update existing)

**Approach:**
- Add `category` enum: support, informational, advocacy, general
- Default to :support for disease groups
- Special groups (newly_diagnosed, general_wellness) get :general

**Test scenarios:**
- Happy path: Auto-created disease group gets :support category
- Edge case: Newly diagnosed group gets :general category

---

### Phase 2: Remove Posts from Dashboard

- [x] **Unit 2.1: Remove post button and post section from dashboard** ✅

**Goal:** Dashboard shows NO posts, no "post" button

**Files:**
- Modify: `app/views/dashboard/index.html.erb`
- Modify: `app/controllers/dashboard_controller.rb`
- Modify: `config/locales/en/dashboard.en.yml`
- Modify: `spec/system/health_tracking_flow_spec.rb`

**Approach:**
- Remove "Add Post" button from dashboard
- Remove "New Posts" section (friends' disease statuses)
- Keep measurement trends, medications, stats grid
- Redirect any direct `/posts` route to groups index

**Patterns to follow:**
- Dashboard layout pattern with BEM CSS classes
- Existing dashboard sections structure

**Test scenarios:**
- Happy path: Dashboard loads without "Add Post" button
- Happy path: Dashboard loads without "New Posts" section
- Edge case: `/diseases/:id/statuses` still accessible directly

---

- [ ] **Unit 2.2: Create PostsController for direct post creation**

**Goal:** Allow direct post creation without 5-click navigation

**Files:**
- Create: `app/controllers/posts_controller.rb`
- Modify: `config/routes.rb`
- Create: `app/views/posts/new.html.erb`
- Create: `app/views/posts/_form.html.erb`
- Create: `spec/requests/posts_controller_spec.rb`
- Create: `config/locales/en/posts.en.yml`

**Approach:**
- `GET /posts/new` — form to create post (select group or "my health update")
- `POST /posts` — create post
- Posts can be: group post OR health status update
- Health status updates appear in friends' feeds

**Patterns to follow:**
- Standard REST controller pattern
- Strong params pattern
- Pagy integration if list view needed

**Test scenarios:**
- Happy path: Create a group post
- Happy path: Create a health status update
- Error path: Validation failure shows form with errors
- Edge case: User without groups can only create health status

---

### Phase 3: Rich Post Types

- [x] **Unit 3.1: Refactor GroupPost into unified Post model** ✅

**Goal:** Single Post model supporting multiple post types

**Files:**
- Create: `db/migrate/20260426210000_create_posts.rb`
- Create: `app/models/post.rb`
- Create: `spec/factories/posts.rb`
- Create: `spec/models/post_spec.rb`
- Modify: `app/models/group.rb` (has_many :posts → Post)
- Modify: `app/controllers/groups/posts_controller.rb` (uses Post)
- Modify: `app/views/groups/posts/_form.html.erb` (uses @post)

**Approach:**
- Create `Post` model with:
  - `post_type` enum: text, link, image, poll, quote
  - `body` (text content)
  - `metadata` (JSONB for link_url, image_data, poll_options, hashtags)
  - `account_id`, `group_id`
  - `quoted_post_id` (for quote posts)
- GroupPost model kept for backwards compatibility

**Test scenarios:**
- Happy path: Create text post ✅
- Happy path: Create link post with URL ✅
- Happy path: Create image post with attachment ✅
- (Poll, quote tests pending - post_type validations work)

**Notes:**
- 13 Post specs passing
- 7 Group specs passing
- 21 system specs passing
- 13 posts_controller request specs passing
- 11 groups_controller request specs passing

---

- [x] **Unit 3.2: Link preview card generation** ✅

**Goal:** Extract metadata from URLs for link posts

**Files:**
- Create: `app/services/link_preview_service.rb`
- Create: `spec/services/link_preview_service_spec.rb`
- Modify: `app/models/post.rb` (add `generate_link_preview` callback)

**Test scenarios:**
- Happy path: Valid URL generates preview ✅
- Edge case: Invalid URL generates no preview (graceful) ✅
- Edge case: URL with no Open Graph tags ✅

---

- [x] **Unit 3.3: Post hashtags** ✅

**Goal:** Parse and store hashtags from post body

**Files:**
- Create: `db/migrate/20260426220000_create_hashtags.rb`
- Create: `app/models/hashtag.rb`
- Create: `app/models/post_hashtag.rb`
- Create: `spec/models/hashtag_spec.rb`
- Create: `spec/factories/hashtags.rb`
- Modify: `app/models/post.rb` (hashtags association + callbacks)

**Test scenarios:**
- Hashtag extraction from body ✅
- Increments post_count after save ✅
- No duplicate post_hashtags ✅
- Edge case: Same hashtag used in multiple posts
- Edge case: Hashtag with numbers (#covid19)

---

- [x] **Unit 3.4: Poll functionality** ✅

**Goal:** Allow creating polls in posts

**Files:**
- Create: `db/migrate/20260426230000_create_poll_options.rb`
- Create: `db/migrate/20260426230001_create_poll_votes.rb`
- Create: `db/migrate/20260426230002_add_poll_votes_count_to_posts.rb`
- Create: `app/models/poll_option.rb`
- Create: `app/models/poll_vote.rb`
- Create: `spec/models/poll_option_spec.rb`
- Create: `spec/models/poll_vote_spec.rb`
- Create: `spec/factories/poll_options.rb`
- Create: `spec/factories/poll_votes.rb`
- Modify: `app/models/post.rb` (poll_options association)

**Test scenarios:**
- Happy path: Create poll with multiple options ✅
- Happy path: User votes on poll (increments vote_count) ✅
- Edge case: User tries to vote twice (uniqueness validation) ✅

---

- [x] **Unit 3.5: Quote-post (reshare with comment)** ✅

**Goal:** Allow resharing any post with a comment

**Files:**
- Create: `db/migrate/20260426231000_add_quote_count_to_posts.rb`
- Modify: `app/models/post.rb` (has_many :quotes, callbacks)
- Modify: `spec/models/post_spec.rb` (quote tests)

**Test scenarios:**
- Quote post belongs to quoted post ✅
- Original post has many quotes ✅
- quote_count increments on quoted post ✅
- quote_post? helper method ✅

---

### Phase 4: Save/Bookmark Posts

- [x] **Unit 4.1: Post bookmark functionality** ✅

**Goal:** Let patients save posts for later

**Files:**
- Create: `app/models/post_bookmark.rb`
- Create: `db/migrate/20260426232000_create_post_bookmarks.rb`
- Create: `db/migrate/20260426232001_add_bookmark_count_to_posts.rb`
- Modify: `app/models/account.rb` (add associations)
- Modify: `app/models/post.rb` (add counter_cache, has_many :post_bookmarks)
- Create: `spec/models/post_bookmark_spec.rb`
- Create: `spec/factories/post_bookmarks.rb`

**Approach:**
- `PostBookmark`: account_id, post_id, created_at
- Unique constraint on (account_id, post_id)
- `Account has_many :post_bookmarks, :post`
- `Account has_many :bookmarked_posts, through: :post_bookmarks`
- `Post has_many :post_bookmarks, dependent: :destroy`
- Counter cache: `bookmark_count` on Post, incremented on create, decremented on destroy

**Patterns to follow:**
- Counter cache pattern using `increment!` / `decrement!` (not `update_all`)
- `after_create` / `after_destroy` callbacks
- Unique constraint from GroupMember

**Test scenarios:**
- Happy path: Bookmark a post ✅
- Happy path: Unbookmark a post ✅
- Happy path: View all bookmarked posts (via association)
- Edge case: Double bookmark (validation prevents)
- Edge case: Bookmark own post (allowed)
- Counter cache increment/decrement ✅

**Note:** Controller/views for `/saved` page not yet implemented - only core model functionality

---

### Phase 5: Reputation/Karma System

- [x] **Unit 5.1: Karma calculation from reactions** ✅

**Goal:** Track user reputation based on received reactions

**Files:**
- Create: `app/models/karma_point.rb`
- Create: `db/migrate/20260426300000_create_karma_points.rb`
- Modify: `app/models/account.rb` (add karma_score, karma_points association)
- Create: `db/migrate/20260426300001_add_karma_score_to_accounts.rb`
- Modify: `app/models/reaction.rb` (add callbacks to create/destroy karma points)
- Modify: `app/models/post.rb` (add karma_points association)
- Create: `spec/models/karma_point_spec.rb`
- Create: `spec/factories/karma_points.rb`
- Modify: `spec/models/account_spec.rb` (add karma_points association test)

**Approach:**
- `KarmaPoint`: account_id, post_id, reaction_type, points
- `Account` has `karma_score` (incremented/decremented via callbacks)
- Points: like=+1, love=+2, sad=+1, haha=+1, angry=-1, dislike=-1
- KarmaPoints created/destroyed via Reaction after_create/around_destroy callbacks
- Only Post reactions create KarmaPoints (polymorphic check)

**Patterns to follow:**
- Counter cache pattern using `increment!` / `decrement!`
- `around_destroy` for proper counter decrement before delete
- Reaction callbacks only trigger for Post reactions

**Test scenarios:**
- Happy path: Like gives +1 karma ✅
- Happy path: Love gives +2 karma ✅
- Happy path: Karma score is SUM of all points ✅
- Edge case: Remove reaction subtracts karma ✅
- Edge case: New account has 0 karma ✅
- Counter cache increment/decrement ✅

---

- [x] **Unit 5.2: Badge/flair system** ✅

**Goal:** Display badges based on karma level

**Files:**
- Modify: `app/models/account.rb` (add badge enum, badge_level, recompute_badge!)
- Create: `db/migrate/20260426310000_add_badge_to_accounts.rb`
- Modify: `app/models/karma_point.rb` (update badge on karma changes)

**Approach:**
- Badge tiers: newcomer (0-10), contributor (11-50), advocate (51-100), expert (101+)
- Badge stored as integer enum on Account
- `badge_level` method computes from karma_score
- `recompute_badge!` updates stored badge when karma changes
- KarmaPoint callbacks call `recompute_badge!` after karma updates

**Patterns to follow:**
- Enum pattern for badge tiers
- Counter cache update pattern

**Test scenarios:**
- Happy path: New user gets "newcomer" badge ✅
- Happy path: Karma 50 user gets "contributor" badge ✅
- Happy path: Karma 101 user gets "expert" badge ✅
- Edge case: Badge recomputes correctly on karma change ✅

**Note:** UI views for displaying badge not yet implemented - only model logic

---

### Phase 6: Patient Profiles

- [x] **Unit 6.1: Public patient profile page** ✅

**Goal:** Display patient profile with activity

**Files:**
- Modify: `app/controllers/accounts_controller.rb` (add @posts)
- Modify: `app/views/accounts/show.html.erb` (add karma, badge, posts)
- Modify: `config/locales/en/views.en.yml` (add i18n keys)
- Modify: `spec/requests/accounts_controller_spec.rb` (add @posts test)

**Approach:**
- Uses existing `GET /accounts/:id` route and AccountsController
- Shows: name, bio, location, birthday, gender, education, karma score, badge, joined date, recent posts
- Privacy: AccountPolicy restricts viewing to owner or friends

**Test scenarios:**
- Happy path: View own profile ✅
- Happy path: View friend's profile with posts ✅
- Edge case: Non-friend redirected ✅
- User with no posts shows empty state ✅

---

- [x] **Unit 6.2: Profile edit/privacy settings** ✅ (PARTIAL)

**Goal:** Let patients control profile visibility

**Files:**
- Existing: `app/models/account.rb` (settings JSONB, privacy_settings method)
- Existing: AccountPolicy (already enforces friends-only visibility)

**Approach:**
- Privacy settings stored in `settings` JSONB column
- `profile_visibility` key: public, friends, private
- AccountPolicy#show? already checks account_owner? || friend?

**Test scenarios:**
- Profile visibility enforced via AccountPolicy ✅

**Note:** Full profile edit UI not implemented, but core privacy infrastructure exists

---

### Phase 7: Group Moderation

- [ ] **Unit 7.1: Group membership roles (moderator)**

**Goal:** Add moderator role to group members

**Files:**
- Modify: `app/models/group_member.rb`
- Create: `db/migrate/20260426320000_add_role_to_group_members.rb`
- Modify: `spec/models/group_member_spec.rb`

**Approach:**
- `GroupMember role` enum: member (0), moderator (1), admin (2)
- First member to join a group becomes admin via `after_create` callback
- Admin can promote members to moderator (not yet implemented)
- Moderators can pin posts, hide posts, warn users (not yet implemented)

**Patterns to follow:**
- Existing role enum pattern (e.g., SpecialistPatient status)
- Counter cache for role counts

**Test scenarios:**
- Happy path: Group creator is admin ✅
- Happy path: Second member is member (not admin) ✅
- Edge case: Non-admin cannot promote (not yet implemented)

---

- [ ] **Unit 7.2: Pin post in group**

**Goal:** Moderators can pin important posts

**Files:**
- Modify: `app/models/post.rb`
- Create: `db/migrate/XXXXXX_add_pinned_to_posts.rb`
- Modify: `app/controllers/groups/posts_controller.rb`
- Create: `app/views/groups/posts/_pin_button.html.erb`
- Modify: `app/views/groups/posts/index.html.erb`
- Modify: `spec/models/group_post_spec.rb` → rename to post_spec

**Approach:**
- `Post` has `pinned_at` datetime (nil = not pinned)
- Only moderators can pin; only one post pinned at a time per group
- Pinned posts appear at top of group feed

**Patterns to follow:**
- Existing pinned/sticky pattern from forums
- Authorization pattern from other moderator actions

**Test scenarios:**
- Happy path: Moderator pins a post
- Happy path: Pinned post appears at top
- Edge case: Pin second post unpins first
- Edge case: Non-moderator cannot pin

---

- [ ] **Unit 7.3: Report post functionality**

**Goal:** Users can report inappropriate posts

**Files:**
- Create: `app/models/post_report.rb`
- Create: `db/migrate/XXXXXX_create_post_reports.rb`
- Create: `app/controllers/post_reports_controller.rb`
- Create: `app/views/posts/_report_button.html.erb`
- Modify: `app/models/post.rb`
- Create: `spec/models/post_report_spec.rb`
- Create: `config/locales/en/post_reports.en.yml`

**Approach:**
- `PostReport`: account_id, post_id, reason, status (pending/reviewed/dismissed)
- Report button on posts (for non-own posts)
- Admin reviews reports (future: moderation dashboard)

**Patterns to follow:**
- Report/flag pattern from community platforms
- Status enum from existing models

**Test scenarios:**
- Happy path: User reports post
- Happy path: Cannot report own post
- Edge case: Duplicate report (idempotent)
- Edge case: Report without reason

---

- [ ] **Unit 7.4: Hide post in group**

**Goal:** Moderators can hide inappropriate posts

**Files:**
- Modify: `app/models/post.rb`
- Create: `db/migrate/XXXXXX_add_hidden_to_posts.rb`
- Modify: `app/controllers/groups/posts_controller.rb`
- Modify: `app/views/groups/posts/_post.html.erb`

**Approach:**
- `Post` has `hidden_at` datetime (nil = visible)
- Hidden posts only visible to author + moderators
- Author sees "This post was hidden by moderators" message

**Test scenarios:**
- Happy path: Moderator hides post
- Happy path: Hidden post not shown to other users
- Happy path: Author sees hidden post with notice
- Edge case: Non-moderator cannot hide

---

### Phase 8: Specialist Presence in Groups

- [x] **Unit 8.1: Specialists can join groups for their patients** ✅

**Goal:** Specialists can participate in disease communities

**Files:**
- Modify: `app/models/group.rb` (add specialist_member?, accessible_by_specialist)
- Modify: `app/models/group_member.rb` (add specialist? method)
- Modify: `spec/models/group_member_spec.rb` (add specialist? tests)

**Approach:**
- Specialists can see groups for diseases their patients have
- `GroupMember#specialist?` checks if member is a specialist with active patients in that disease
- `Group.accessible_by_specialist` scope returns groups for a specialist's patients' diseases

**Test scenarios:**
- Happy path: Specialist sees patient disease groups ✅
- Happy path: Specialist has badge in group ✅
- Edge case: Specialist without patients sees no groups ✅

---

- [x] **Unit 8.2: Pin expert response (specialist)** ✅

**Goal:** Specialists can pin their responses as expert answers

**Files:**
- Modify: `app/models/comment.rb` (add expert_pinned_at, pin_as_expert!, unpin_as_expert!)
- Create: `db/migrate/20260426400000_add_expert_pinned_at_to_comments.rb`
- Modify: `spec/models/comment_spec.rb` (add expert pinning tests)

**Approach:**
- `Comment` has `expert_pinned_at` datetime
- Only specialists with active patients can pin comments via `pin_as_expert!`
- `Comment#expert_pinned?` checks if comment is pinned
- `Comment.expert_pinned` scope returns only pinned comments

**Test scenarios:**
- Happy path: Specialist pins their comment ✅
- Happy path: Expert pin appears at top ✅
- Edge case: Non-specialist cannot pin ✅
- Edge case: Specialist without patients cannot pin ✅

---

### Phase 9: Cross-Disease Communities

- [x] **Unit 9.1: Special cross-disease groups** ✅

**Goal:** Create general wellness, newly diagnosed groups

**Files:**
- Create: `db/migrate/20260426410000_add_special_to_predefined_diseases.rb`
- Modify: `app/models/predefined_disease.rb` (add special scope and flag)
- Modify: `app/models/group.rb` (add special?, accessible_to_all? methods)
- Modify: `app/controllers/groups_controller.rb` (special groups visible to all)
- Modify: `spec/models/predefined_disease_spec.rb` (add special group tests)

**Approach:**
- Add `special` boolean flag to PredefinedDisease
- Special groups always visible to all patients (no membership required)
- Special groups have category: :general
- GroupsController shows special groups separately and allows viewing without joining

**Test scenarios:**
- Happy path: Special groups visible to all ✅
- Happy path: Special groups have general category ✅
- Happy path: Non-special groups require membership ✅

---

- [ ] **Unit 9.2: Onboarding nudge for new diagnoses** (DEFERRED)

**Goal:** Prompt patients to join disease community when diagnosed

**Files:**
- Create: `app/models/disease.rb` (add after_create callback)
- Create: `app/services/disease_onboarding_service.rb`
- Create: `app/views/disease_statuses/_join_group_nudge.html.erb`
- Modify: `app/views/diseases/show.html.erb`
- Create: `spec/models/disease_spec.rb`

**Approach:**
- When `Disease` created (patient diagnosed), check if group exists
- If group exists and patient not member, show nudge on disease page
- Nudge: "Join the [Disease] community" with one-click join button
- Dismissed via `dismissed_group_nudge_ids` in account settings

**Status:** Deferred - requires UI views and Disease model callbacks

---

### Phase 10: Feed Refinement

- [ ] **Unit 10.1: Social feed page (replaces dashboard posts)**

**Goal:** Proper social feed combining group posts + friends' health updates

**Files:**
- Create: `app/controllers/feeds_controller.rb`
- Create: `app/views/feeds/show.html.erb`
- Create: `app/services/feed_service.rb`
- Modify: `config/routes.rb`
- Create: `spec/requests/feeds_controller_spec.rb`
- Create: `config/locales/en/feeds.en.yml`

**Approach:**
- `GET /feed` — combined feed
- Feed items: group posts from patient's groups + friends' disease statuses
- Pagy pagination
- Sorted by created_at DESC
- Each item type rendered differently

**Patterns to follow:**
- Pagy pattern from groups controller
- Mixed-type feed rendering pattern

**Test scenarios:**
- Happy path: Feed shows group posts
- Happy path: Feed shows friends' health updates
- Happy path: Feed sorted by recency
- Edge case: Empty feed shows onboarding

---

- [ ] **Unit 10.2: Remove DiseaseStatus from dashboard**

**Goal:** Ensure DiseaseStatus only appears in feeds, not dashboard

**Files:**
- Modify: `app/views/dashboard/index.html.erb`
- Modify: `app/controllers/dashboard_controller.rb`
- Modify: `spec/system/health_tracking_flow_spec.rb`

**Approach:**
- Remove DiseaseStatus rendering from dashboard
- Dashboard stays: measurements, medications, stats
- Health updates now only in `/feed`

**Test scenarios:**
- Happy path: Dashboard has no posts
- Edge case: `/feed` still shows DiseaseStatus from friends

---

## System-Wide Impact

### Interaction Graph
- Post creation → triggers notification to group members
- Reaction → updates karma_points for post author
- Group membership → affects feed composition
- Disease diagnosis → may trigger onboarding nudge

### Error Propagation
- Failed post creation → form redisplay with errors
- Failed reaction → graceful failure, no visible error to user
- Feed load failure → show cached content if available

### State Lifecycle Risks
- **Post delete**: cascade delete reactions, comments, quotes (handled by `dependent: :destroy`)
- **Account delete**: cascade delete posts, group memberships, karma_points
- **Group delete**: posts become orphaned (use soft delete or nullify)

### API Surface Parity
- If mobile app exists, same endpoints must support post types
- Consider RESTful `/posts` and `/posts/:id/reactions` patterns

### Integration Coverage
- Feed generation crosses multiple models (integration test needed)
- Karma calculation needs transaction test

### Unchanged Invariants
- Chatrooms remain separate from group posts
- Friendships unchanged
- SpecialistPatient relationship unchanged

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| Breaking existing group specs | Update specs alongside code changes |
| Complex feed query performance | Add indexes, consider materialized view for later |
| Karma calculation race conditions | Use `increment_counter` with locking |
| Poll voting race conditions | Unique constraint on (poll_option_id, account_id) |
| Image upload storage | Use existing Shrine/uploader infrastructure |

## Deferred Implementation Notes

- Real-time feed updates via ActionCable — deferred to future
- Push notifications — deferred to future
- Advanced search (hashtags, users) — deferred to future
- Direct messages between patients — existing chatrooms sufficient

## Test Suite Impact

After implementing these features, the following specs will need updates:
- `spec/system/social_flow_spec.rb` — update for new group filtering
- `spec/system/health_tracking_flow_spec.rb` — remove post-related tests
- `spec/models/group_spec.rb` — add category tests
- `spec/models/group_post_spec.rb` — migrate to post_spec
- Any spec relying on dashboard showing posts

## Execution Posture

**TDD-first**: Every unit begins with failing specs, then implementation. No implementation without tests for new features. Existing tests updated to reflect new behavior.

## Dependencies

1. Unit 1.1 must complete before 1.2 (group filtering pattern)
2. Phase 2 (dashboard removal) should complete before Phase 10 (feed)
3. Unit 3.1 (Post model) must complete before all subsequent Phase 3 units
4. Phase 4 (bookmarks) depends on Post model from Phase 3.1
5. Phase 5 (karma) depends on Reaction system working
6. Phase 7 (moderation) depends on Post model and GroupMember roles
7. Phase 8 (specialist) depends on SpecialistPatient relationship
8. Phase 10 (feed) depends on Post model, Group membership, and DiseaseStatus

## Sequence

1. Phase 1 (Disease-Group Access) — foundation
2. Phase 2 (Dashboard cleanup) — quick win, removes confusion
3. Phase 3 (Rich Post Types) — core data model change
4. Phase 4 (Bookmarks) — simple addition
5. Phase 5 (Karma) — depends on reactions working
6. Phase 6 (Profiles) — independent
7. Phase 7 (Moderation) — depends on Post model
8. Phase 8 (Specialist) — depends on SpecialistPatient
9. Phase 9 (Cross-disease) — special groups
10. Phase 10 (Feed) — integration of everything
