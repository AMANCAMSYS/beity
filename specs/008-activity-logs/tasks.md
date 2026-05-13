# Tasks: Activity Logs

**Input**: Design documents from `/specs/008-activity-logs/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/activity-log-repository.md

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Database migration and feature directory scaffolding

- [x] T001 Create migration file with actor_name column, indexes, and trigger functions in supabase/migrations/20260513_add_activity_log_triggers.sql
- [x] T002 Create feature directory structure under lib/features/activity_logs/ (data/models, data/repositories, domain/entities, presentation/providers, presentation/screens, presentation/widgets)
- [x] T003 [P] Create ActionType and EntityType enums with ActivityLog domain entity in lib/features/activity_logs/domain/entities/activity_log.dart
- [x] T004 [P] Create ActivityLogModel with fromJson/toJson mappers in lib/features/activity_logs/data/models/activity_log_model.dart
- [x] T005 [P] Create ActivityActor model in lib/features/activity_logs/domain/entities/activity_log.dart (add to same file as ActivityLog)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Repository and providers that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T006 Create abstract ActivityLogRepository interface in lib/features/activity_logs/data/repositories/activity_log_repository.dart
- [x] T007 Implement SupabaseActivityLogRepository with watchHomeActivity, watchListActivity, getActivityLogs, getHomeActors in lib/features/activity_logs/data/repositories/supabase_activity_log_repository.dart
- [x] T008 Create activityLogsProvider, homeActivityProvider, listActivityProvider, activityActorsProvider, and activityFilterProvider in lib/features/activity_logs/presentation/providers/activity_logs_provider.dart

**Checkpoint**: Foundation ready — user story implementation can now begin in parallel

---

## Phase 3: User Story 1 — View Activity Feed for a Home (Priority: P1) 🎯 MVP

**Goal**: Home members can view a chronological feed of all recent activities in their home

**Independent Test**: Open the activity feed screen, verify it shows a reverse-chronological list of activities with actor name, action description, entity name, and timestamp. Verify empty state when no activity exists.

### Implementation for User Story 1

- [x] T009 [P] [US1] Create ActivityLogTileWidget displaying actor name, action summary, entity name, and relative timestamp in lib/features/activity_logs/presentation/widgets/activity_log_tile_widget.dart
- [x] T010 [US1] Create ActivityFeedScreen with real-time stream, infinite scroll, empty state, and RTL support in lib/features/activity_logs/presentation/screens/activity_feed_screen.dart
- [x] T011 [US1] Register activity feed route (/activity) in lib/app/router/app_router.dart

**Checkpoint**: Home-level activity feed is fully functional with real-time updates and empty state

---

## Phase 4: User Story 2 — Track Shopping List Changes (Priority: P1)

**Goal**: Activity log entries are automatically created when shopping lists are created, renamed, archived, or deleted

**Independent Test**: Create, rename, archive, and delete shopping lists. Verify each action generates the correct activity log entry with proper action type, entity name, and metadata (old/new names for renames).

### Implementation for User Story 2

- [x] T012 [US2] Verify and fix log_shopping_list_activity() trigger handles INSERT (list_created), UPDATE title (list_renamed), UPDATE status→archived (list_archived), UPDATE deleted_at (list_deleted) in supabase/migrations/20260513_add_activity_log_triggers.sql
- [x] T013 [US2] Verify activity log entries appear in home feed after shopping list CRUD operations — manual test with existing shopping list screens

**Checkpoint**: Shopping list actions are fully tracked in the activity log

---

## Phase 5: User Story 3 — Track Shopping Item Changes (Priority: P1)

**Goal**: Activity log entries are automatically created when items are added, edited, purchased, unpurchased, or deleted

**Independent Test**: Add, edit, mark purchased, unmark, and delete items. Verify each action generates the correct activity log entry with list_id in metadata for list-level filtering.

### Implementation for User Story 3

- [x] T014 [US3] Verify and fix log_shopping_item_activity() trigger handles INSERT (item_added), UPDATE fields (item_updated), UPDATE status→completed (item_purchased), UPDATE status→pending (item_unpurchased), UPDATE deleted_at (item_deleted) in supabase/migrations/20260513_add_activity_log_triggers.sql
- [x] T015 [US3] Verify activity log entries include list_id and list_name in metadata for item actions — manual test with existing shopping item screens

**Checkpoint**: Shopping item actions are fully tracked in the activity log with list context

---

## Phase 6: User Story 4 — Track Membership Changes (Priority: P2)

**Goal**: Activity log entries are automatically created when members join, are removed, have roles changed, or accept invitations

**Independent Test**: Invite a member, accept invitation, change role, remove member. Verify each action generates the correct activity log entry.

### Implementation for User Story 4

- [x] T016 [US4] Verify and fix log_home_member_activity() trigger handles INSERT status=active (member_joined), UPDATE deleted_at (member_removed), UPDATE role (member_role_changed) in supabase/migrations/20260513_add_activity_log_triggers.sql
- [x] T017 [US4] Create log_invitation_activity() trigger for UPDATE status→accepted (invitation_accepted) in supabase/migrations/20260513_add_activity_log_triggers.sql
- [x] T018 [US4] Verify membership and invitation activity appears in home feed — manual test with invitation and member management screens

**Checkpoint**: Membership and invitation actions are fully tracked

---

## Phase 7: User Story 5 — Filter Activity Logs (Priority: P2)

**Goal**: Users can filter the activity feed by actor and action type, and clear filters

**Independent Test**: Open activity feed, filter by a specific member — verify only their actions show. Filter by action type (e.g., "purchases") — verify only matching entries show. Clear filter — verify all entries return.

### Implementation for User Story 5

- [x] T019 [P] [US5] Create ActivityFilterWidget with actor dropdown and action type chips in lib/features/activity_logs/presentation/widgets/activity_filter_widget.dart
- [x] T020 [US5] Update ActivityFeedScreen to integrate filter widget and apply filters to the query in lib/features/activity_logs/presentation/screens/activity_feed_screen.dart
- [x] T021 [US5] Implement getActivityLogs with actorId and actionTypes filter parameters in lib/features/activity_logs/data/repositories/supabase_activity_log_repository.dart

**Checkpoint**: Activity feed supports filtering by actor and action type

---

## Phase 8: User Story 6 — View List-Level Activity (Priority: P2)

**Goal**: Users can view activity logs scoped to a specific shopping list, showing both list-level and item-level actions

**Independent Test**: Open a shopping list's activity view. Verify only actions related to that list appear (list renames, item adds, purchases, etc.). Verify real-time updates work. Verify deleted item entries show with disabled links.

### Implementation for User Story 6

- [x] T022 [US6] Create ListActivityScreen with real-time stream filtered to specific list in lib/features/activity_logs/presentation/screens/list_activity_screen.dart
- [x] T023 [US6] Implement watchListActivity query filtering by entity_type=shopping_list AND entity_id OR metadata->>list_id in lib/features/activity_logs/data/repositories/supabase_activity_log_repository.dart
- [x] T024 [US6] Register list activity route (/lists/:id/activity) in lib/app/router/app_router.dart
- [x] T025 [US6] Add "Activity" button/tab to shopping list detail screen in lib/features/shopping_lists/presentation/screens/shopping_list_detail_screen.dart

**Checkpoint**: List-level activity view is fully functional

---

## Phase 9: User Story 7 — View Activity Details (Priority: P3)

**Goal**: Users can tap an activity entry to see full details including before/after values for edits

**Independent Test**: Tap an activity entry, verify detail view shows full action description, before/after values for edits, and a link to the affected resource (disabled if deleted).

### Implementation for User Story 7

- [x] T026 [US7] Create ActivityDetailScreen showing full action description, metadata (before/after values), entity link, and disabled state for deleted resources in lib/features/activity_logs/presentation/screens/activity_detail_screen.dart
- [x] T027 [US7] Register activity detail route (/activity/:id) in lib/app/router/app_router.dart
- [x] T028 [US7] Add tap navigation from ActivityLogTileWidget to ActivityDetailScreen in lib/features/activity_logs/presentation/widgets/activity_log_tile_widget.dart

**Checkpoint**: Activity detail view is fully functional

---

## Phase 10: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T029 [P] Add Arabic translations for all activity action descriptions (e.g., "أنشأ قائمة [اسم القائمة]" for list_created) in lib/core/utils/ and presentation files
- [x] T030 Verify RTL layout works correctly on all activity log screens (feed, list activity, detail, filter widget)
- [x] T031 Run flutter analyze and fix any issues
- [x] T032 Verify real-time updates work on both home feed and list activity views (< 3s propagation)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 (T001-T005) — BLOCKS all user stories
- **US1 (Phase 3)**: Depends on Phase 2 — core feed screen
- **US2 (Phase 4)**: Depends on Phase 1 (migration) — triggers generate data that US1 displays
- **US3 (Phase 5)**: Depends on Phase 1 (migration) — triggers generate data that US1 displays
- **US4 (Phase 6)**: Depends on Phase 1 (migration) — triggers generate data that US1 displays
- **US5 (Phase 7)**: Depends on Phase 3 (US1 feed screen) — adds filter to existing feed
- **US6 (Phase 8)**: Depends on Phase 2 — uses repository watchListActivity
- **US7 (Phase 9)**: Depends on Phase 3 (US1 tile widget) — adds detail view from tile
- **Polish (Phase 10)**: Depends on all user stories

### User Story Dependencies

- **US1 (P1)**: Depends on Foundational (Phase 2) — No dependencies on other stories
- **US2 (P1)**: Depends on migration (T001) only — triggers work independently of UI
- **US3 (P1)**: Depends on migration (T001) only — triggers work independently of UI
- **US4 (P2)**: Depends on migration (T001) only — triggers work independently of UI
- **US5 (P2)**: Depends on US1 (feed screen exists to add filters to)
- **US6 (P2)**: Depends on Foundational (Phase 2) — independent of US1/US2/US3
- **US7 (P3)**: Depends on US1 (tile widget exists to add tap navigation from)

### Parallel Opportunities

- T003, T004, T005 can run in parallel (different files)
- T009 can run in parallel with T010 (widget vs screen)
- US2, US3, US4 trigger verification can run in parallel after migration
- US5 and US6 can run in parallel (different screens)
- T019, T022, T026 can run in parallel (different screen files)

---

## Parallel Example: Foundational Phase

```bash
# Launch all entity/model tasks together:
Task: "Create ActionType and EntityType enums with ActivityLog domain entity in lib/features/activity_logs/domain/entities/activity_log.dart"
Task: "Create ActivityLogModel with fromJson/toJson mappers in lib/features/activity_logs/data/models/activity_log_model.dart"
Task: "Create ActivityActor model in lib/features/activity_logs/domain/entities/activity_log.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (migration + directory + entities)
2. Complete Phase 2: Foundational (repository + providers)
3. Complete Phase 3: User Story 1 (home feed screen)
4. **STOP and VALIDATE**: Open app, navigate to activity feed, verify real-time updates
5. Deploy/demo if ready

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. Add US1 + US2 + US3 → Test: feed shows list and item activity → Deploy (MVP!)
3. Add US4 → Test: membership changes tracked → Deploy
4. Add US5 + US6 → Test: filtering and list-level view → Deploy
5. Add US7 → Test: detail view → Deploy
6. Polish → Arabic RTL verified, analyze passes → Final deploy

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: US1 (feed screen) + US5 (filters)
   - Developer B: US2 + US3 (trigger verification)
   - Developer C: US6 (list-level view)
3. Then: Developer A adds US7 (detail view), Developer C adds US4 (membership triggers)
4. All converge on Polish

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- US2, US3, US4 are primarily about database triggers — the UI already exists from US1
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
