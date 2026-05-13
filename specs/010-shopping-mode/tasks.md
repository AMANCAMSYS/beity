# Tasks: Shopping Mode

**Input**: Design documents from `/specs/010-shopping-mode/`
**Prerequisites**: plan.md (required), spec.md (required), data-model.md, contracts/, research.md, quickstart.md

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization, database migration, and dependency setup

- [x] T001 Add `wakelock_plus` dependency to `pubspec.yaml`
- [x] T002 Create shopping mode feature directory structure per plan at `lib/features/shopping_mode/`
- [x] T003 Create database migration for `shopping_mode_sessions` table at `supabase/migrations/20260513_add_shopping_mode_sessions.sql`

**Checkpoint**: Project structure ready, database migration applied

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core data layer and session management that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 [P] Create `ShoppingModeSession` entity at `lib/features/shopping_mode/domain/entities/shopping_mode_session.dart`
- [x] T005 [P] Create `ShoppingModeSessionModel` data model at `lib/features/shopping_mode/data/models/shopping_mode_session_model.dart`
- [x] T006 Create `ShoppingModeRepository` abstract interface at `lib/features/shopping_mode/data/repositories/shopping_mode_repository.dart`
- [x] T007 Create `SupabaseShoppingModeRepository` implementation at `lib/features/shopping_mode/data/repositories/supabase_shopping_mode_repository.dart`
- [x] T008 [P] Create `StartShoppingSessionUseCase` at `lib/features/shopping_mode/domain/usecases/start_shopping_session_usecase.dart`
- [x] T009 [P] Create `EndShoppingSessionUseCase` at `lib/features/shopping_mode/domain/usecases/end_shopping_session_usecase.dart`
- [x] T010 [P] Create `GetActiveSessionUseCase` at `lib/features/shopping_mode/domain/usecases/get_active_session_usecase.dart`
- [x] T011 [P] Create `GetShoppingHistoryUseCase` at `lib/features/shopping_mode/domain/usecases/get_shopping_history_usecase.dart`
- [x] T012 Create `ShoppingModeSessionProvider` at `lib/features/shopping_mode/presentation/providers/shopping_mode_session_provider.dart`
- [x] T013 Create `ShoppingModeProvider` (main state: isActive, searchQuery, collapsedCategories) at `lib/features/shopping_mode/presentation/providers/shopping_mode_provider.dart`
- [x] T014 Create `ShoppingModeItemsProvider` (filtered/grouped items with real-time subscription) at `lib/features/shopping_mode/presentation/providers/shopping_mode_items_provider.dart`

**Checkpoint**: Data layer, use cases, and providers ready — user story implementation can now begin

---

## Phase 3: User Story 1 — Enter Shopping Mode (Priority: P1) 🎯 MVP

**Goal**: User can enter a dedicated shopping mode from a shopping list with a focused, large-touch-target interface

**Independent Test**: Open a shopping list, tap "Start Shopping", verify UI switches to simplified large-card view

### Implementation for User Story 1

- [x] T015 [P] [US1] Create `ShoppingItemCard` widget at `lib/features/shopping_mode/presentation/widgets/shopping_item_card.dart`
- [x] T016 [P] [US1] Create `ShoppingCategoryGroup` widget at `lib/features/shopping_mode/presentation/widgets/shopping_category_group.dart`
- [x] T017 [US1] Create `ShoppingModeScreen` main screen at `lib/features/shopping_mode/presentation/screens/shopping_mode_screen.dart`
- [x] T018 [US1] Add "Start Shopping" button to existing shopping list screen at `lib/features/shopping_lists/presentation/screens/shopping_list_detail_screen.dart`
- [x] T019 [US1] Add shopping mode route to GoRouter configuration

**Checkpoint**: User can enter shopping mode, see items in large-card layout grouped by category

---

## Phase 4: User Story 2 — Mark Items as Purchased (Priority: P1) 🎯 MVP

**Goal**: User can mark items as purchased with a single tap, with visual feedback and real-time sync

**Independent Test**: Tap an item card in shopping mode, verify it shows purchased state and syncs to other devices

### Implementation for User Story 2

- [x] T020 [US2] Implement tap-to-purchase toggle in `ShoppingItemCard` widget at `lib/features/shopping_mode/presentation/widgets/shopping_item_card.dart`
- [x] T021 [US2] Implement purchased item visual state (strikethrough, muted color, sunk to category bottom) in `ShoppingModeItemsProvider` at `lib/features/shopping_mode/presentation/providers/shopping_mode_items_provider.dart`
- [x] T022 [US2] Add real-time sync for item purchase state changes via Supabase Realtime subscription in `ShoppingModeItemsProvider`
- [x] T023 [US2] Display purchaser name and timestamp on purchased items in `ShoppingItemCard`

**Checkpoint**: Users can mark items purchased with single tap, changes sync in real-time across devices

---

## Phase 5: User Story 3 — Browse Items by Category (Priority: P1) 🎯 MVP

**Goal**: Items are grouped by category with collapsible headers, auto-collapse when category complete

**Independent Test**: Enter shopping mode with items in multiple categories, verify grouping and collapse behavior

### Implementation for User Story 3

- [x] T024 [US3] Implement category grouping logic in `ShoppingModeItemsProvider` at `lib/features/shopping_mode/presentation/providers/shopping_mode_items_provider.dart`
- [x] T025 [US3] Implement collapsible category headers with auto-collapse for completed categories in `ShoppingCategoryGroup` at `lib/features/shopping_mode/presentation/widgets/shopping_category_group.dart`
- [x] T026 [US3] Add "Other" group for uncategorized items at end of list in `ShoppingModeScreen`
- [x] T027 [US3] Add completion indicator (✓) on fully purchased categories in `ShoppingCategoryGroup`

**Checkpoint**: Items grouped by category, completed categories auto-collapse with checkmark

---

## Phase 6: User Story 4 — Add Items Quickly (Priority: P1) 🎯 MVP

**Goal**: User can quickly add items via a minimal overlay with autocomplete and consecutive additions

**Independent Test**: Tap add button in shopping mode, type item name, verify item appears in list immediately

### Implementation for User Story 4

- [x] T028 [P] [US4] Create `ShoppingQuickAddOverlay` widget at `lib/features/shopping_mode/presentation/widgets/shopping_quick_add_overlay.dart`
- [x] T029 [US4] Implement autocomplete from item templates and previously added items in `ShoppingQuickAddOverlay`
- [x] T030 [US4] Implement "Add Another" behavior to keep overlay open for consecutive additions in `ShoppingQuickAddOverlay`
- [x] T031 [US4] Add floating action button to `ShoppingModeScreen` that opens `ShoppingQuickAddOverlay`

**Checkpoint**: Users can quickly add items without leaving shopping mode, consecutive additions supported

---

## Phase 7: User Story 5 — See Shopping Progress (Priority: P2)

**Goal**: User sees progress bar and count at a glance, completion message when all items purchased

**Independent Test**: Mark items as purchased, verify progress indicator updates correctly

### Implementation for User Story 5

- [x] T032 [P] [US5] Create `ShoppingProgressBar` widget at `lib/features/shopping_mode/presentation/widgets/shopping_progress_bar.dart`
- [x] T033 [US5] Integrate `ShoppingProgressBar` into `ShoppingModeScreen` app bar
- [x] T034 [US5] Implement completion message with exit option when all items purchased in `ShoppingModeScreen`

**Checkpoint**: Progress indicator shows real-time count, completion message appears when done

---

## Phase 8: User Story 6 — Search Items (Priority: P2)

**Goal**: User can search/filter items within shopping mode by item name

**Independent Test**: Enter search term, verify only matching items displayed

### Implementation for User Story 6

- [x] T035 [P] [US6] Create `ShoppingModeSearchBar` widget at `lib/features/shopping_mode/presentation/widgets/shopping_mode_search_bar.dart`
- [x] T036 [US6] Implement search filtering logic in `ShoppingModeItemsProvider` at `lib/features/shopping_mode/presentation/providers/shopping_mode_items_provider.dart`
- [x] T037 [US6] Integrate `ShoppingModeSearchBar` into `ShoppingModeScreen` with real-time filtering

**Checkpoint**: Users can search items within shopping mode, results update as they type

---

## Phase 9: User Story 7 — Exit Shopping Mode (Priority: P2)

**Goal**: User can exit shopping mode with summary and confirmation for unpurchased items

**Independent Test**: Tap "Done Shopping", verify summary shows and returns to normal list view

### Implementation for User Story 7

- [x] T038 [P] [US7] Create `ShoppingExitSummary` widget at `lib/features/shopping_mode/presentation/widgets/shopping_exit_summary.dart`
- [x] T039 [US7] Implement exit confirmation dialog for unpurchased items in `ShoppingModeScreen`
- [x] T040 [US7] Implement "Done Shopping" button with summary flow in `ShoppingModeScreen`
- [x] T041 [US7] Handle back button/swipe to show exit confirmation in `ShoppingModeScreen`
- [x] T042 [US7] End shopping session and update `ended_at` on exit via `EndShoppingSessionUseCase`

**Checkpoint**: Users can exit with summary, confirmation prevents accidental exit with unpurchased items

---

## Phase 10: User Story 8 — Shopping Mode Stays Awake (Priority: P3)

**Goal**: Screen stays awake while in shopping mode, restores normal timeout on exit

**Independent Test**: Enter shopping mode, verify screen does not dim or lock

### Implementation for User Story 8

- [x] T043 [US8] Implement `WakelockPlus.enable()` on entering shopping mode in `ShoppingModeScreen`
- [x] T044 [US8] Implement `WakelockPlus.disable()` on exiting shopping mode in `ShoppingModeScreen`

**Checkpoint**: Screen stays awake during shopping, normal timeout restored on exit

---

## Phase 11: User Story 9 — Quick Item Quantity Adjustment (Priority: P3)

**Goal**: User can quickly adjust item quantities with inline +/- controls

**Independent Test**: Tap quantity on item card, verify inline controls appear and quantity updates

### Implementation for User Story 9

- [x] T045 [P] [US9] Create `ShoppingQuantityControls` widget at `lib/features/shopping_mode/presentation/widgets/shopping_quantity_controls.dart`
- [x] T046 [US9] Integrate `ShoppingQuantityControls` into `ShoppingItemCard` with tap-to-show behavior
- [x] T047 [US9] Implement real-time quantity sync on change in `ShoppingQuantityControls`

**Checkpoint**: Users can adjust quantities inline, changes sync in real-time

---

## Phase 12: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T048 [P] Add Arabic RTL support to all shopping mode widgets (text alignment, icon mirroring, layout direction)
- [x] T049 [P] Implement empty state for shopping mode (no items message with prompt to add)
- [x] T050 [P] Add haptic feedback on item purchase toggle
- [x] T051 Optimize list rendering for 200+ items (ListView.builder with const widgets)
- [x] T052 Handle edge case: item deleted by another user while in shopping mode (remove with brief notification)
- [x] T053 Handle edge case: network interruption during operations (queue locally, sync on reconnect)
- [x] T054 Run `flutter analyze` and fix any issues

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories
- **User Stories (Phase 3–11)**: All depend on Foundational phase completion
  - US1–US4 (P1): Must complete first for core shopping mode to work
  - US5–US7 (P2): Can proceed after P1 stories are functional
  - US8–US9 (P3): Can proceed after P2 stories are functional
- **Polish (Phase 12)**: Depends on all user stories being complete

### User Story Dependencies

- **US1 (Enter)**: Depends on Foundational — enables entry point
- **US2 (Mark Purchased)**: Depends on US1 — needs shopping mode screen active
- **US3 (Categories)**: Depends on US1 — needs shopping mode screen, can work alongside US2
- **US4 (Quick Add)**: Depends on US1 — needs shopping mode screen active
- **US5 (Progress)**: Depends on US2 — needs purchased count to display
- **US6 (Search)**: Depends on US1 — needs shopping mode screen active
- **US7 (Exit)**: Depends on US2 — needs purchased data for summary
- **US8 (Screen Awake)**: Depends on US1 — needs shopping mode screen active
- **US9 (Quantity)**: Depends on US1 — needs item cards displayed

### Within Each User Story

- Models before services
- Services before providers
- Providers before widgets
- Widgets before screen integration
- Core implementation before edge cases

### Parallel Opportunities

- T004, T005 can run in parallel (entity + model)
- T008, T009, T010, T011 can run in parallel (all use cases)
- T015, T016 can run in parallel (independent widgets)
- T028, T032, T035, T038, T045 can run in parallel (independent widgets)
- US8 and US9 can be developed in parallel with each other

---

## Parallel Example: User Story 1

```bash
# Launch widget tasks together (different files):
Task: "Create ShoppingItemCard widget at lib/features/shopping_mode/presentation/widgets/shopping_item_card.dart"
Task: "Create ShoppingCategoryGroup widget at lib/features/shopping_mode/presentation/widgets/shopping_category_group.dart"

# Then integrate into screen:
Task: "Create ShoppingModeScreen main screen at lib/features/shopping_mode/presentation/screens/shopping_mode_screen.dart"
```

---

## Implementation Strategy

### MVP First (User Stories 1–4)

1. Complete Phase 1: Setup (migration, structure, dependency)
2. Complete Phase 2: Foundational (session model, repository, use cases, providers)
3. Complete Phase 3: Enter Shopping Mode (screen, item cards, category groups)
4. Complete Phase 4: Mark as Purchased (tap toggle, visual state, real-time sync)
5. Complete Phase 5: Category Browsing (grouping, collapse, completion indicator)
6. Complete Phase 6: Quick Add (overlay, autocomplete, consecutive additions)
7. **STOP and VALIDATE**: Test core shopping mode independently
8. Deploy/demo if ready

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. US1+US2+US3+US4 → Core shopping mode (MVP!)
3. US5 → Progress indicator
4. US6 → Search
5. US7 → Exit summary
6. US8 → Screen awake
7. US9 → Quantity adjustment
8. Polish → RTL, edge cases, performance

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Reuses existing `shopping_items` table — no new item schema needed
- Real-time sync via existing Supabase Realtime subscriptions from SPEC 007
