# Tasks: Realtime Sync

**Input**: Design documents from `/specs/007-realtime-sync/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/realtime-service.md

**Organization**: Tasks grouped by user story for independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4)
- Include exact file paths in descriptions

## Phase 1: Setup

**Purpose**: Add dependencies and create shared realtime infrastructure

- [x] T001 Add `connectivity_plus` dependency to pubspec.yaml
- [x] T002 Create `RealtimeService` class in `lib/core/services/realtime_service.dart` with methods: `watchTable()`, `watchPresence()`, `connectionState`, `fetchMissedChanges()`, `disposeAll()`
- [x] T003 Create `PresenceState` and `PresencePayload` model classes in `lib/core/services/realtime_service.dart`
- [x] T004 Create `ConnectionState` and `ConnectionStatus` model classes in `lib/core/services/realtime_service.dart`
- [x] T005 Create `OfflineQueueEntry` model and `QueueOperation` enum in `lib/core/services/realtime_service.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Connection state and offline queue providers that all user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T006 Create `connectionStateProvider` (StreamProvider) in `lib/features/shopping_lists/presentation/providers/realtime_providers.dart` that wraps `RealtimeService.connectionState`
- [x] T007 Create `offlineQueueProvider` (StateNotifierProvider) in `lib/features/shopping_lists/presentation/providers/realtime_providers.dart` managing a list of `OfflineQueueEntry` with methods: `enqueue()`, `flush()`, `discard()`, `pendingCount`
- [x] T008 Create `realtimeServiceProvider` (Provider) in `lib/features/shopping_lists/presentation/providers/realtime_providers.dart` that instantiates `RealtimeService` with `Supabase.instance.client`

**Checkpoint**: Foundation ready — user story implementation can begin

---

## Phase 3: User Story 1 — Live Shopping List Updates (Priority: P1) 🎯 MVP

**Goal**: Changes to shopping list items appear instantly on all connected devices with conflict feedback

**Independent Test**: Open same list on 2 devices → add/edit/delete item on one → verify it appears on the other within 1 second. Edit same item on both → verify toast + highlight on overwritten device.

### Implementation for User Story 1

- [x] T009 [US1] Add conflict detection to `SupabaseShoppingListRepository.watchShoppingItems()` in `lib/features/shopping_lists/data/repositories/supabase_shopping_list_repository.dart` — track `updated_at` of last local mutation, emit conflict event when incoming `updated_at` > local timestamp
- [x] T010 [US1] Create `conflictEventProvider` (StreamProvider) in `lib/features/shopping_lists/presentation/providers/shopping_items_provider.dart` that emits `{itemId, updatedBy}` when a conflict is detected
- [x] T011 [P] [US1] Create `ItemUpdatedToast` widget in `lib/features/shopping_lists/presentation/widgets/item_updated_toast.dart` — shows "Item updated by [name]" snackbar, auto-dismisses after 3s
- [x] T012 [P] [US1] Create item highlight logic in `lib/features/shopping_lists/presentation/widgets/shopping_item_tile_widget.dart` — accept `highlightUntil` parameter, apply 3s yellow background animation when set
- [x] T013 [US1] Integrate conflict toast + highlight in `ShoppingListDetailScreen` in `lib/features/shopping_lists/presentation/screens/shopping_list_detail_screen.dart` — listen to `conflictEventProvider`, show toast, set `highlightUntil` on affected item
- [x] T014 [US1] Enhance `shoppingListsProvider` in `lib/features/shopping_lists/presentation/providers/shopping_lists_provider.dart` to use `RealtimeService.watchTable()` for home-level list changes (new list created by other member appears instantly)

**Checkpoint**: User Story 1 complete — realtime item sync with conflict feedback working

---

## Phase 4: User Story 2 — Online Presence Indicators (Priority: P2)

**Goal**: Show which family members are currently viewing the same shopping list

**Independent Test**: Open same list on 2 devices with different users → verify each device shows the other user's avatar/initials. One user leaves → indicator disappears within 5s.

### Implementation for User Story 2

- [x] T015 [US2] Add presence tracking to `RealtimeService.watchPresence()` implementation in `lib/core/services/realtime_service.dart` — join `presence:list:<list_id>` channel on subscribe, track join/leave events
- [x] T016 [US2] Create `presenceProvider` (StreamProvider.family) in `lib/features/shopping_lists/presentation/providers/shopping_items_provider.dart` — keyed by `listId`, returns `Map<String, PresenceState>` from `RealtimeService.watchPresence()`
- [x] T017 [US2] Create `PresenceIndicatorWidget` in `lib/features/shopping_lists/presentation/widgets/presence_indicator_widget.dart` — displays row of CircleAvatar with user initials, tooltip with full name
- [x] T018 [US2] Integrate `PresenceIndicatorWidget` in `ShoppingListDetailScreen` in `lib/features/shopping_lists/presentation/screens/shopping_list_detail_screen.dart` — show below app bar, listen to `presenceProvider(listId)`
- [x] T019 [US2] Add presence join on screen enter and leave on screen dispose in `ShoppingListDetailScreen` in `lib/features/shopping_lists/presentation/screens/shopping_list_detail_screen.dart` — call `RealtimeService.joinPresence()` in `initState`, `leavePresence()` in `dispose`

**Checkpoint**: User Story 2 complete — presence indicators showing who's viewing each list

---

## Phase 5: User Story 3 — Home-Level Realtime Updates (Priority: P2)

**Goal**: Home membership, roles, and categories sync in real-time. Removed members are redirected with a dialog.

**Independent Test**: On device A, add member to home. On device B (on categories screen), verify new member appears. Remove device B user from home → verify dialog + redirect.

### Implementation for User Story 3

- [x] T020 [US3] Create `homeMembersStreamProvider` (StreamProvider.family) in `lib/features/homes/presentation/providers/homes_provider.dart` — wraps `RealtimeService.watchTable()` filtered by `home_id`
- [x] T021 [US3] Create `categoriesStreamProvider` (StreamProvider.family) in `lib/features/categories/presentation/providers/categories_provider.dart` — wraps `RealtimeService.watchTable()` filtered by `home_id`
- [x] T022 [US3] Add removed-member detection in `lib/features/home/presentation/screens/home_screen.dart` — listen to `homeMembersStreamProvider`, check if current user's membership was deleted, show dialog "You have been removed from [home name]" and redirect to homes list
- [x] T023 [US3] Replace `FutureProvider` with `StreamProvider` for categories list in `lib/features/categories/presentation/screens/categories_list_screen.dart` — use `categoriesStreamProvider` for live updates
- [x] T024 [US3] Replace `FutureProvider` with `StreamProvider` for home members in `lib/features/homes/presentation/screens/manage_roles_screen.dart` — use `homeMembersStreamProvider` for live updates

**Checkpoint**: User Story 3 complete — home-level data syncs in real-time, removed members redirected

---

## Phase 6: User Story 4 — Connection Status Awareness (Priority: P3)

**Goal**: Users see connection status and sync progress indicators

**Independent Test**: Enable airplane mode while viewing list → verify "Disconnected" banner. Reconnect → verify "Syncing..." progress → verify missed updates appear.

### Implementation for User Story 4

- [x] T025 [P] [US4] Create `ConnectionStatusWidget` in `lib/features/shopping_lists/presentation/widgets/connection_status_widget.dart` — shows red "Disconnected" banner when offline, blue "Syncing..." progress bar when reconnecting
- [x] T026 [US4] Integrate `ConnectionStatusWidget` in `ShoppingListDetailScreen` in `lib/features/shopping_lists/presentation/screens/shopping_list_detail_screen.dart` — listen to `connectionStateProvider`, show widget at top of list
- [x] T027 [US4] Implement offline queue flush on reconnect in `lib/features/shopping_lists/presentation/providers/realtime_providers.dart` — when `connectionState` transitions to `connected`, call `offlineQueue.flush()` to execute queued mutations
- [x] T028 [US4] Add discard-with-warning on logout in `lib/features/auth/presentation/providers/auth_provider.dart` — before sign out, check `offlineQueueProvider.pendingCount`, if >0 show confirmation dialog, then call `offlineQueue.discard()`
- [x] T029 [US4] Implement `fetchMissedChanges()` in `RealtimeService` in `lib/core/services/realtime_service.dart` — query Supabase for rows with `updated_at > lastConnectedAt`, used on reconnect to fill gaps

**Checkpoint**: User Story 4 complete — connection status visible, offline queue syncs on reconnect

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Cleanup and validation across all stories

- [x] T030 Run `flutter analyze` and fix all warnings
- [x] T031 Ensure all new widgets support Arabic RTL layout (text direction, alignment)
- [x] T032 Verify all realtime subscriptions are cleaned up on logout (no dangling channels)
- [x] T033 Run quickstart.md validation scenarios

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 (needs RealtimeService)
- **US1 (Phase 3)**: Depends on Phase 2 — core realtime sync
- **US2 (Phase 4)**: Depends on Phase 2 — can run parallel with US1
- **US3 (Phase 5)**: Depends on Phase 2 — can run parallel with US1/US2
- **US4 (Phase 6)**: Depends on Phase 2 — can run parallel with US1/US2/US3
- **Polish (Phase 7)**: Depends on all desired user stories

### User Story Dependencies

- **US1 (P1)**: Can start after Phase 2. No dependencies on other stories.
- **US2 (P2)**: Can start after Phase 2. Integrates with US1's detail screen but independently testable.
- **US3 (P2)**: Can start after Phase 2. Uses different providers (homes, categories). Removed-member detection touches home_screen.
- **US4 (P3)**: Can start after Phase 2. Uses connectionStateProvider and offlineQueueProvider from Phase 2. Integrates into US1's detail screen.

### Within Each User Story

- Models/providers before widgets
- Widgets before screen integration
- Core implementation before integration

### Parallel Opportunities

- T003, T004, T005 can run in parallel (different model classes in same file)
- T011, T012 can run in parallel (different widget files)
- T025 can run in parallel with US1/US2/US3 (independent widget)
- US1, US2, US3 can all start in parallel after Phase 2

---

## Parallel Example: After Phase 2

```bash
# All three user stories can start simultaneously:
Task: "T009 [US1] Add conflict detection to watchShoppingItems()"
Task: "T015 [US2] Add presence tracking to RealtimeService"
Task: "T020 [US3] Create homeMembersStreamProvider"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T005)
2. Complete Phase 2: Foundational (T006-T008)
3. Complete Phase 3: US1 (T009-T014)
4. **STOP and VALIDATE**: Open list on 2 devices, verify sync + conflict toast
5. Deploy/demo if ready

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. Add US1 → Test realtime item sync → Deploy (MVP!)
3. Add US2 → Test presence → Deploy
4. Add US3 → Test home-level sync + removed member → Deploy
5. Add US4 → Test connection status + offline queue → Deploy

---

## Notes

- Existing `.stream(primaryKey:)` usage on shopping_items and shopping_lists is the foundation. Tasks enhance, not replace.
- No new database tables needed. Presence is ephemeral. Offline queue is in-memory.
- `connectivity_plus` is the only new dependency.
- All new widgets must support RTL Arabic layout.
