# Tasks: Offline Queue

**Input**: Design documents from `/specs/011-offline-queue/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 Add Isar and connectivity_plus dependencies to pubspec.yaml
- [x] T002 Create feature directory structure under lib/features/offline_queue/
- [x] T003 Create test directory structure under tests/unit/features/offline_queue/, tests/widget/features/offline_queue/, tests/integration/features/offline_queue/

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 [P] Create ActionType enum in lib/features/offline_queue/domain/entities/action_type.dart
- [x] T005 [P] Create EntityType enum in lib/features/offline_queue/domain/entities/entity_type.dart
- [x] T006 [P] Create SyncStatus enum in lib/features/offline_queue/domain/entities/sync_status.dart
- [x] T007 [P] Create DeviceSyncStatus enum in lib/features/offline_queue/domain/entities/device_sync_status.dart
- [x] T008 Create QueueEntry entity in lib/features/offline_queue/domain/entities/queue_entry.dart
- [x] T009 [P] Create OfflineQueueRepository abstract interface in lib/features/offline_queue/data/repositories/offline_queue_repository.dart
- [x] T010 [P] Create ConnectivityRepository abstract interface in lib/features/offline_queue/data/repositories/connectivity_repository.dart
- [x] T011 Create QueueEntryModel (Isar model) in lib/features/offline_queue/data/models/queue_entry_model.dart
- [x] T012 Create IsarQueueDataSource in lib/features/offline_queue/data/datasources/isar_queue_datasource.dart
- [x] T013 Create IsarOfflineQueueRepository implementation in lib/features/offline_queue/data/repositories/isar_offline_queue_repository.dart
- [x] T014 Create ConnectivityDataSource using connectivity_plus in lib/features/offline_queue/data/datasources/connectivity_datasource.dart
- [x] T015 Create SupabaseConnectivityRepository implementation in lib/features/offline_queue/data/repositories/supabase_connectivity_repository.dart

**Checkpoint**: Foundation ready — user story implementation can now begin

---

## Phase 3: User Story 1 — Queue Actions While Offline (Priority: P1) 🎯 MVP

**Goal**: Capture shopping list actions locally when offline and sync automatically when connectivity is restored

**Independent Test**: Enable airplane mode, perform multiple shopping actions (add, update, delete, mark purchased), disable airplane mode, verify all actions sync correctly.

### Implementation for User Story 1

- [x] T016 [P] [US1] Create EnqueueActionUseCase in lib/features/offline_queue/domain/usecases/enqueue_action_usecase.dart
- [x] T017 [P] [US1] Create SyncQueueUseCase in lib/features/offline_queue/domain/usecases/sync_queue_usecase.dart
- [x] T018 [P] [US1] Create GetPendingCountUseCase in lib/features/offline_queue/domain/usecases/get_pending_count_usecase.dart
- [x] T019 [P] [US1] Create GetQueueEntriesUseCase in lib/features/offline_queue/domain/usecases/get_queue_entries_usecase.dart
- [x] T020 [US1] Create OfflineQueueProvider (Riverpod) in lib/features/offline_queue/presentation/providers/offline_queue_provider.dart
- [x] T021 [US1] Create ConnectivityProvider (Riverpod) in lib/features/offline_queue/presentation/providers/connectivity_provider.dart
- [x] T022 [US1] Create SyncStatusProvider (Riverpod) in lib/features/offline_queue/presentation/providers/sync_status_provider.dart
- [x] T023 [US1] Create OfflineModeIndicator widget in lib/features/offline_queue/presentation/widgets/offline_mode_indicator.dart
- [x] T024 [US1] Integrate offline queue with existing shopping_items feature (wrap repository calls)

**Checkpoint**: User Story 1 complete — offline queue captures and syncs actions

---

## Phase 4: User Story 2 — View Pending Sync Status (Priority: P2)

**Goal**: Display visual indicators on items with pending changes and show overall sync status

**Independent Test**: Go offline, make changes, verify visual indicators appear on modified items and in a status area.

### Implementation for User Story 2

- [x] T025 [P] [US2] Create PendingSyncIndicator widget in lib/features/offline_queue/presentation/widgets/pending_sync_indicator.dart
- [x] T026 [P] [US2] Create SyncStatusBanner widget in lib/features/offline_queue/presentation/widgets/sync_status_banner.dart
- [x] T027 [P] [US2] Create QueueEntryTile widget in lib/features/offline_queue/presentation/widgets/queue_entry_tile.dart
- [x] T028 [US2] Integrate PendingSyncIndicator into shopping item cards
- [x] T029 [US2] Add SyncStatusBanner to shopping list screen header

**Checkpoint**: User Story 2 complete — users can see pending sync status

---

## Phase 5: User Story 3 — Handle Sync Conflicts (Priority: P3)

**Goal**: Resolve conflicts using last-write-wins when offline changes conflict with server state

**Independent Test**: Two users modify the same item while one is offline; verify conflict is resolved using last-write-wins when offline user reconnects.

### Implementation for User Story 3

- [x] T030 [US3] Add conflict detection logic to SyncQueueUseCase (compare local timestamp with server updated_at)
- [x] T031 [US3] Add conflict notification logic (notify user when their offline changes were overwritten)
- [x] T032 [US3] Add conflict resolution UI feedback in SyncStatusBanner

**Checkpoint**: User Story 3 complete — conflicts resolved with last-write-wins

---

## Phase 6: User Story 4 — Manual Retry for Failed Syncs (Priority: P4)

**Goal**: Allow users to manually retry failed sync actions

**Independent Test**: Simulate a sync failure, verify retry option appears, confirm action succeeds after issue is resolved.

### Implementation for User Story 4

- [x] T033 [P] [US4] Create RetryFailedActionUseCase in lib/features/offline_queue/domain/usecases/retry_failed_action_usecase.dart
- [x] T034 [P] [US4] Create RetryButton widget in lib/features/offline_queue/presentation/widgets/retry_button.dart
- [x] T035 [US4] Add retry functionality to QueueEntryTile
- [x] T036 [US4] Add "Retry All" action to SyncStatusBanner for failed entries

**Checkpoint**: User Story 4 complete — users can retry failed syncs

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T037 [P] Ensure Arabic RTL layout for all offline_queue widgets
- [x] T038 [P] Add Isar schema initialization to app startup in lib/main.dart
- [x] T039 Add offline queue provider overrides to ProviderScope in lib/app/
- [x] T040 Run flutter analyze and fix any issues

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories
- **User Stories (Phase 3-6)**: All depend on Foundational phase completion
  - US1 (P1) can start after Phase 2
  - US2 (P2) can start after Phase 2 (independent of US1 but integrates with it)
  - US3 (P3) depends on US1 (requires sync logic)
  - US4 (P4) can start after Phase 2 (independent of other stories)
- **Polish (Phase 7)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) — No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) — Integrates with US1 but independently testable
- **User Story 3 (P3)**: Depends on US1 (uses SyncQueueUseCase for conflict detection)
- **User Story 4 (P4)**: Can start after Foundational (Phase 2) — Uses existing queue infrastructure

### Within Each User Story

- Models before services
- Services before providers
- Providers before widgets
- Core implementation before integration

### Parallel Opportunities

- All Setup tasks (T001-T003) can run in parallel
- All Foundational enum tasks (T004-T007) can run in parallel
- All Foundational repository tasks (T009-T010) can run in parallel
- All US1 use case tasks (T016-T019) can run in parallel
- All US2 widget tasks (T025-T027) can run in parallel
- All US4 tasks (T033-T034) can run in parallel
- US1, US2, and US4 can be worked on in parallel after Phase 2

---

## Parallel Example: User Story 1

```bash
# Launch all use cases for User Story 1 together:
Task: "Create EnqueueActionUseCase in lib/features/offline_queue/domain/usecases/enqueue_action_usecase.dart"
Task: "Create SyncQueueUseCase in lib/features/offline_queue/domain/usecases/sync_queue_usecase.dart"
Task: "Create GetPendingCountUseCase in lib/features/offline_queue/domain/usecases/get_pending_count_usecase.dart"
Task: "Create GetQueueEntriesUseCase in lib/features/offline_queue/domain/usecases/get_queue_entries_usecase.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test offline queue captures and syncs actions
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 → Test independently → Deploy/Demo
4. Add User Story 3 → Test independently → Deploy/Demo
5. Add User Story 4 → Test independently → Deploy/Demo
6. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 + User Story 3
   - Developer B: User Story 2 + User Story 4
3. Stories complete and integrate independently

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
