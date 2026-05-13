# Tasks: Shopping Lists

**Input**: Design documents from `/specs/005-shopping-lists/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 Create feature directory structure per implementation plan
- [x] T002 [P] Create shopping_list_model.dart in lib/features/shopping_lists/data/models/shopping_list_model.dart
- [x] T003 [P] Create shopping_item_model.dart in lib/features/shopping_lists/data/models/shopping_item_model.dart
- [x] T004 [P] Create item_template_model.dart in lib/features/shopping_lists/data/models/item_template_model.dart

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T005 Create shopping_list_repository.dart interface in lib/features/shopping_lists/data/repositories/shopping_list_repository.dart
- [x] T006 Create supabase_shopping_list_repository.dart implementation in lib/features/shopping_lists/data/repositories/supabase_shopping_list_repository.dart
- [x] T007 [P] Create shopping_list.dart entity in lib/features/shopping_lists/domain/entities/shopping_list.dart
- [x] T008 [P] Create shopping_item.dart entity in lib/features/shopping_lists/domain/entities/shopping_item.dart
- [x] T009 [P] Create item_template.dart entity in lib/features/shopping_lists/domain/entities/item_template.dart
- [x] T010 Create shopping_lists_provider.dart in lib/features/shopping_lists/presentation/providers/shopping_lists_provider.dart
- [x] T011 Create shopping_items_provider.dart in lib/features/shopping_lists/presentation/providers/shopping_items_provider.dart

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Create Shopping List (Priority: P1) 🎯 MVP

**Goal**: Enable users to create new shopping lists within their home

**Independent Test**: Can be fully tested by creating a new shopping list and verifying it appears in the list of shopping lists for the home.

### Implementation for User Story 1

- [x] T012 [US1] Create create_shopping_list_usecase.dart in lib/features/shopping_lists/domain/usecases/create_shopping_list_usecase.dart
- [x] T013 [US1] Create get_shopping_lists_usecase.dart in lib/features/shopping_lists/domain/usecases/get_shopping_lists_usecase.dart
- [x] T014 [US1] Create shopping_lists_screen.dart in lib/features/shopping_lists/presentation/screens/shopping_lists_screen.dart
- [x] T015 [US1] Create shopping_list_card_widget.dart in lib/features/shopping_lists/presentation/widgets/shopping_list_card_widget.dart

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - Add Items to Shopping List (Priority: P1)

**Goal**: Enable users to add items with name, quantity, unit, category, and optional price

**Independent Test**: Can be tested by adding multiple items to a list and verifying they appear in the list with correct details.

### Implementation for User Story 2

- [x] T016 [US2] Create add_item_usecase.dart in lib/features/shopping_lists/domain/usecases/add_item_usecase.dart
- [x] T017 [US2] Create get_shopping_items_usecase.dart in lib/features/shopping_lists/domain/usecases/get_shopping_items_usecase.dart
- [x] T018 [US2] Create shopping_list_detail_screen.dart in lib/features/shopping_lists/presentation/screens/shopping_list_detail_screen.dart
- [x] T019 [US2] Create add_item_screen.dart in lib/features/shopping_lists/presentation/screens/add_item_screen.dart
- [x] T020 [US2] Create shopping_item_tile_widget.dart in lib/features/shopping_lists/presentation/widgets/shopping_item_tile_widget.dart
- [x] T021 [US2] Create item_suggestions_widget.dart in lib/features/shopping_lists/presentation/widgets/item_suggestions_widget.dart
- [x] T022 [US2] Create category_filter_widget.dart in lib/features/shopping_lists/presentation/widgets/category_filter_widget.dart
- [x] T022b [US2] Integrate unit types from categories feature in lib/features/shopping_lists/presentation/screens/add_item_screen.dart

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - Mark Items as Purchased (Priority: P1)

**Goal**: Enable users to mark items as purchased/unpurchased with visual indicators

**Independent Test**: Can be tested by marking items as purchased and verifying they are visually distinguished from unpurchased items.

### Implementation for User Story 3

- [x] T023 [US3] Create mark_item_purchased_usecase.dart in lib/features/shopping_lists/domain/usecases/mark_item_purchased_usecase.dart
- [x] T024 [US3] Update shopping_item_tile_widget.dart with purchase toggle UI in lib/features/shopping_lists/presentation/widgets/shopping_item_tile_widget.dart
- [x] T024b [US3] Create purchase history query in lib/features/shopping_lists/data/repositories/supabase_shopping_list_repository.dart

**Checkpoint**: At this point, User Stories 1, 2, and 3 should all work independently

---

## Phase 6: User Story 4 - Real-time Collaboration (Priority: P2)

**Goal**: Enable real-time synchronization of list changes across all home members

**Independent Test**: Can be tested by having two users view the same list and verify that changes from one appear on the other's device immediately.

### Implementation for User Story 4

- [x] T025 [US4] Add Supabase Realtime subscription to shopping_items_provider.dart in lib/features/shopping_lists/presentation/providers/shopping_items_provider.dart
- [x] T026 [US4] Add Supabase Realtime subscription to shopping_lists_provider.dart in lib/features/shopping_lists/presentation/providers/shopping_lists_provider.dart
- [x] T027 [US4] Implement optimistic updates in providers for instant UI feedback

**Checkpoint**: At this point, real-time collaboration should be working

---

## Phase 7: User Story 5 - Edit and Remove Items (Priority: P2)

**Goal**: Enable users to edit or remove items from a shopping list

**Independent Test**: Can be tested by editing item details and removing items, then verifying the changes are reflected correctly.

### Implementation for User Story 5

- [x] T028 [US5] Create update_item_usecase.dart in lib/features/shopping_lists/domain/usecases/update_item_usecase.dart
- [x] T029 [US5] Create delete_item_usecase.dart in lib/features/shopping_lists/domain/usecases/delete_item_usecase.dart
- [x] T030 [US5] Create edit_item_screen.dart in lib/features/shopping_lists/presentation/screens/edit_item_screen.dart
- [x] T031 [US5] Add swipe-to-edit and swipe-to-delete gestures to shopping_item_tile_widget.dart

**Checkpoint**: At this point, item editing and deletion should be working

---

## Phase 8: User Story 6 - Shopping List Management (Priority: P2)

**Goal**: Enable users to rename, archive, and delete shopping lists

**Independent Test**: Can be tested by performing management operations on lists and verifying they work correctly.

### Implementation for User Story 6

- [x] T032 [US6] Create archive_list_usecase.dart in lib/features/shopping_lists/domain/usecases/archive_list_usecase.dart
- [x] T033 [US6] Create delete_list_usecase.dart in lib/features/shopping_lists/domain/usecases/delete_list_usecase.dart
- [x] T034 [US6] Add swipe-to-archive and swipe-to-delete gestures to shopping_list_card_widget.dart
- [x] T035 [US6] Add rename functionality to shopping_list_card_widget.dart
- [x] T036 [US6] Implement archived lists section in shopping_lists_screen.dart

**Checkpoint**: At this point, list management should be fully functional

---

## Phase 9: User Story 7 - Quick Add from Favorites (Priority: P3)

**Goal**: Enable users to quickly add frequently purchased items from a favorites list

**Independent Test**: Can be tested by adding items from favorites and verifying they appear in the shopping list.

### Implementation for User Story 7

- [x] T037 [US7] Create quick_add_screen.dart in lib/features/shopping_lists/presentation/screens/quick_add_screen.dart
- [x] T038 [US7] Create item_template_repository.dart in lib/features/shopping_lists/data/repositories/item_template_repository.dart
- [x] T039 [US7] Add quick add button to shopping_list_detail_screen.dart

**Checkpoint**: At this point, quick add from favorites should be working

---

## Phase 10: User Story 8 - Shopping List Summary (Priority: P3)

**Goal**: Enable users to see a summary of their shopping list with totals

**Independent Test**: Can be tested by viewing the summary and verifying it shows the correct information.

### Implementation for User Story 8

- [x] T040 [US8] Create list_summary_screen.dart in lib/features/shopping_lists/presentation/screens/list_summary_screen.dart
- [x] T041 [US8] Add summary button to shopping_list_detail_screen.dart
- [x] T042 [US8] Implement category breakdown and price totals in list_summary_screen.dart

**Checkpoint**: At this point, list summary should be working

---

## Phase 11: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T043 [P] Create offline_sync_helper.dart in lib/core/utils/offline_sync_helper.dart
- [x] T044 Implement basic offline caching with Isar for shopping lists and items
- [x] T045 [P] Add Arabic RTL support to all new screens and widgets
- [x] T046 [P] Add search functionality to shopping_list_detail_screen.dart
- [x] T047 Implement notifications for item additions and purchases via Firebase FCM
- [x] T048 Add empty states for all screens with helpful guidance
- [x] T049 Run quickstart.md validation

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P1)**: Can start after Foundational (Phase 2) - Depends on US1 for list context
- **User Story 3 (P1)**: Can start after Foundational (Phase 2) - Depends on US2 for items to mark
- **User Story 4 (P2)**: Can start after Foundational (Phase 2) - Enhances US1/US2/US3 with real-time
- **User Story 5 (P2)**: Can start after Foundational (Phase 2) - Depends on US2 for items to edit
- **User Story 6 (P2)**: Can start after Foundational (Phase 2) - Depends on US1 for lists to manage
- **User Story 7 (P3)**: Can start after US2 - Requires item adding functionality
- **User Story 8 (P3)**: Can start after US2 - Requires items to summarize

### Within Each User Story

- Models before services
- Services before endpoints
- Core implementation before integration
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- Once Foundational phase completes, all user stories can start in parallel (if team capacity allows)
- Models within a story marked [P] can run in parallel
- Different user stories can be worked on in parallel by different team members

---

## Parallel Example: User Story 1

```bash
# Launch all models for User Story 1 together:
Task: "Create shopping_list_model.dart in lib/features/shopping_lists/data/models/shopping_list_model.dart"
Task: "Create shopping_item_model.dart in lib/features/shopping_lists/data/models/shopping_item_model.dart"
Task: "Create item_template_model.dart in lib/features/shopping_lists/data/models/item_template_model.dart"

# Launch all entities for User Story 1 together:
Task: "Create shopping_list.dart entity in lib/features/shopping_lists/domain/entities/shopping_list.dart"
Task: "Create shopping_item.dart entity in lib/features/shopping_lists/domain/entities/shopping_item.dart"
Task: "Create item_template.dart entity in lib/features/shopping_lists/domain/entities/item_template.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test User Story 1 independently
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 → Test independently → Deploy/Demo
4. Add User Story 3 → Test independently → Deploy/Demo
5. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1
   - Developer B: User Story 2
   - Developer C: User Story 3
3. Stories complete and integrate independently

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
