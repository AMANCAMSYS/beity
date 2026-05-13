# Tasks: Inventory Phase

**Input**: Design documents from `/specs/013-inventory-phase/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization, database migration, and feature directory structure

- [X] T001 Create inventory feature directory structure at lib/features/inventory/{data/{models,repositories},domain/{entities,usecases},presentation/{providers,screens,widgets}}
- [X] T002 Create Supabase migration for inventory_items and inventory_transactions tables in supabase/migrations/20260513000000_create_inventory_tables.sql
- [X] T003 Register inventory feature routes in GoRouter configuration in lib/app/router/app_router.dart

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core data layer, domain layer, and repository that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T004 [P] Create InventoryItemModel with JSON serialization in lib/features/inventory/data/models/inventory_item_model.dart
- [X] T005 [P] Create InventoryTransactionModel with JSON serialization in lib/features/inventory/data/models/inventory_transaction_model.dart
- [X] T006 [P] Create InventoryItem entity with validation logic in lib/features/inventory/domain/entities/inventory_item.dart
- [X] T007 [P] Create InventoryTransaction entity in lib/features/inventory/domain/entities/inventory_transaction.dart
- [X] T008 Define InventoryRepository interface with all CRUD + query methods in lib/features/inventory/data/repositories/inventory_repository.dart
- [X] T009 Implement SupabaseInventoryRepository with Supabase client operations in lib/features/inventory/data/repositories/supabase_inventory_repository.dart
- [X] T010 Create inventoryProvider with Supabase Realtime subscription filtered by home_id in lib/features/inventory/presentation/providers/inventory_provider.dart

**Checkpoint**: Foundation ready — user story implementation can now begin

---

## Phase 3: User Story 1 — View Home Inventory (Priority: P1) 🎯 MVP

**Goal**: Home members can view all inventory items grouped by category with quantity, unit, and empty state handling

**Independent Test**: Open the inventory screen and verify all items appear grouped by category with name, quantity, unit, and low-stock badges; verify empty state when no items exist

### Implementation for User Story 1

- [X] T011 [P] [US1] Create InventoryItemTile widget displaying name, quantity, unit, category, and low-stock badge in lib/features/inventory/presentation/widgets/inventory_item_tile.dart
- [X] T012 [P] [US1] Create LowStockBadge widget for items at or below min_quantity threshold in lib/features/inventory/presentation/widgets/low_stock_badge.dart
- [X] T013 [P] [US1] Create CategoryGroupHeader widget for grouped inventory list sections in lib/features/inventory/presentation/widgets/category_group_header.dart
- [X] T014 [US1] Implement GetInventoryItemsUseCase with category grouping logic in lib/features/inventory/domain/usecases/get_inventory_items_usecase.dart
- [X] T015 [US1] Build InventoryScreen with categorized list, empty state, and FAB for adding items in lib/features/inventory/presentation/screens/inventory_screen.dart

**Checkpoint**: User Story 1 complete — inventory viewable with category grouping and empty state

---

## Phase 4: User Story 2 — Add Item to Inventory (Priority: P1)

**Goal**: Home members can add new inventory items with auto-suggest, duplicate detection, and optional category/notes/threshold

**Independent Test**: Add an item with name, quantity, unit, category, notes, and min_quantity; verify it appears in inventory; verify duplicate detection merges quantities; verify auto-suggest works

### Implementation for User Story 2

- [X] T016 [US2] Implement AddInventoryItemUseCase with duplicate detection (case-insensitive name + same unit_id merges quantity) in lib/features/inventory/domain/usecases/add_inventory_item_usecase.dart
- [X] T017 [US2] Build AddInventoryItemScreen with name field (auto-suggest from item templates and inventory), quantity, unit picker, category picker, min_quantity, and notes fields in lib/features/inventory/presentation/screens/add_inventory_item_screen.dart
- [X] T018 [US2] Add inventory item auto-suggest search method to SupabaseInventoryRepository using ilike name matching in lib/features/inventory/data/repositories/supabase_inventory_repository.dart

**Checkpoint**: User Stories 1 and 2 complete — can view and add inventory items

---

## Phase 5: User Story 3 — Update Inventory Quantity (Priority: P1)

**Goal**: Home members can update item quantities using quick-adjust buttons (±1 for whole units, ±0.5 for fractional) or manual input, with auto-removal at zero and real-time sync

**Independent Test**: Tap quick-adjust buttons on an item; verify quantity changes by correct step; reduce to zero and verify item is removed; verify real-time sync to other members

### Implementation for User Story 3

- [X] T019 [P] [US3] Create QuantityAdjusterWidget with plus/minus buttons that use ±1 for whole units and ±0.5 for fractional units (kg, liters) in lib/features/inventory/presentation/widgets/quantity_adjuster_widget.dart
- [X] T020 [US3] Implement UpdateInventoryQuantityUseCase with transaction logging, zero-quantity auto-removal, and low-stock evaluation in lib/features/inventory/domain/usecases/update_inventory_quantity_usecase.dart
- [X] T021 [US3] Build EditInventoryItemScreen with inline quantity adjuster, editable fields (name, category, unit, min_quantity, notes), and save/cancel actions in lib/features/inventory/presentation/screens/edit_inventory_item_screen.dart

**Checkpoint**: User Stories 1-3 complete — core inventory CRUD operational with real-time sync

---

## Phase 6: User Story 4 — Remove Item from Inventory (Priority: P2)

**Goal**: Home members can manually delete inventory items with a confirmation dialog

**Independent Test**: Long-press or swipe an item, confirm deletion, verify item no longer appears in inventory

### Implementation for User Story 4

- [X] T022 [US4] Implement DeleteInventoryItemUseCase with soft-delete and transaction logging (change_reason: 'delete') in lib/features/inventory/domain/usecases/delete_inventory_item_usecase.dart
- [X] T023 [US4] Add delete confirmation dialog and swipe-to-delete gesture to InventoryItemTile in lib/features/inventory/presentation/widgets/inventory_item_tile.dart
- [X] T024 [US4] Build InventoryItemDetailScreen showing item details, transaction history, and delete action in lib/features/inventory/presentation/screens/inventory_item_detail_screen.dart
- [X] T025 [US4] Create InventoryTransactionsProvider to fetch and stream transaction history for an item in lib/features/inventory/presentation/providers/inventory_transactions_provider.dart

**Checkpoint**: User Stories 1-4 complete — full inventory CRUD with audit trail

---

## Phase 7: User Story 5 — Add Inventory Item to Shopping List (Priority: P2)

**Goal**: Home members can add low-stock inventory items to a selected shopping list with auto-calculated restock quantity

**Independent Test**: Select a low-stock item, tap "Add to Shopping List," choose a list, verify item appears in shopping list with suggested quantity = (threshold × 2) − current quantity

### Implementation for User Story 5

- [X] T026 [US5] Implement AddToShoppingListUseCase with restock quantity calculation, shopping list item duplicate detection, and inventory transaction logging in lib/features/inventory/domain/usecases/add_to_shopping_list_usecase.dart
- [ ] T027 [US5] Add "Add to Shopping List" action to InventoryItemDetailScreen with shopping list selector bottom sheet in lib/features/inventory/presentation/screens/inventory_item_detail_screen.dart

**Checkpoint**: User Stories 1-5 complete — inventory-to-shopping-list bridge operational

---

## Phase 8: User Story 6 — Mark Shopping Item as "Add to Inventory" (Priority: P3)

**Goal**: When marking a shopping item as purchased, users can opt to also add it to inventory (upsert with duplicate detection)

**Independent Test**: Mark a shopping item as purchased with "Add to Inventory" toggle on; verify item appears in inventory or existing item quantity increases

### Implementation for User Story 6

- [X] T028 [US6] Implement AddPurchasedToInventoryUseCase with upsert logic (merge by name + unit_id), transaction logging (change_reason: 'shopping_restock') in lib/features/inventory/domain/usecases/add_purchased_to_inventory_usecase.dart
- [ ] T029 [US6] Add "Add to Inventory" toggle to the existing mark-as-purchased flow in shopping items feature in lib/features/shopping_lists/domain/usecases/mark_item_purchased_usecase.dart
- [ ] T030 [US6] Wire AddPurchasedToInventoryUseCase into the mark-as-purchased provider when toggle is enabled in lib/features/shopping_lists/presentation/providers/shopping_items_provider.dart

**Checkpoint**: All user stories complete — bidirectional inventory ↔ shopping list integration

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [X] T031 [P] Add RTL (Arabic) layout support to all inventory screens and widgets in lib/features/inventory/presentation/
- [X] T032 [P] Add inventory route to bottom navigation bar or home screen in lib/app/router/app_router.dart
- [ ] T033 Wire inventory item into offline queue for add/update/delete operations in lib/features/inventory/data/repositories/supabase_inventory_repository.dart
- [X] T034 Run flutter analyze and fix any linting issues across lib/features/inventory/

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories
- **US1 — View Inventory (Phase 3)**: Depends on Foundational (Phase 2)
- **US2 — Add Item (Phase 4)**: Depends on Foundational (Phase 2); benefits from US1 (can test add → view)
- **US3 — Update Quantity (Phase 5)**: Depends on Foundational (Phase 2); benefits from US1+US2
- **US4 — Remove Item (Phase 6)**: Depends on Foundational (Phase 2); independent of US1-US3
- **US5 — Add to Shopping List (Phase 7)**: Depends on US1+US2+US3 (needs inventory items to exist)
- **US6 — Purchased to Inventory (Phase 8)**: Depends on US2 (needs AddInventoryItemUseCase); modifies existing shopping_lists feature
- **Polish (Phase 9)**: Depends on all user stories being complete

### User Story Dependencies

- **US1 (P1)**: Can start after Phase 2 — No dependencies on other stories
- **US2 (P1)**: Can start after Phase 2 — No dependencies on other stories
- **US3 (P1)**: Can start after Phase 2 — No dependencies on other stories
- **US4 (P2)**: Can start after Phase 2 — No dependencies on other stories
- **US5 (P2)**: Depends on US1+US2+US3 (needs inventory items to add to shopping list)
- **US6 (P3)**: Depends on US2 (needs AddInventoryItemUseCase); integrates with existing shopping_lists

### Within Each User Story

- Models before services (already in Phase 2)
- Services before UI
- Core implementation before integration
- Story complete before moving to next priority

### Parallel Opportunities

- Phase 2 tasks T004, T005, T006, T007 can run in parallel (different files)
- Phase 3 tasks T011, T012, T013 can run in parallel (different widget files)
- Phase 5 task T019 can run in parallel with T020 (different files)
- US1, US2, US3 can be developed in parallel after Phase 2 (different screens, shared data layer)
- US4 can be developed in parallel with US1-US3 (independent delete flow)
- Polish tasks T031, T032 can run in parallel (different files)

---

## Parallel Example: User Story 1

```bash
# Launch all widget tasks for US1 together:
Task: "Create InventoryItemTile widget in lib/features/inventory/presentation/widgets/inventory_item_tile.dart"
Task: "Create LowStockBadge widget in lib/features/inventory/presentation/widgets/low_stock_badge.dart"
Task: "Create CategoryGroupHeader widget in lib/features/inventory/presentation/widgets/category_group_header.dart"

# After widgets complete, build the screen:
Task: "Build InventoryScreen in lib/features/inventory/presentation/screens/inventory_screen.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (migration, directory structure)
2. Complete Phase 2: Foundational (models, entities, repository, provider)
3. Complete Phase 3: User Story 1 (view inventory)
4. **STOP and VALIDATE**: Open inventory screen, verify items display grouped by category
5. Deploy/demo if ready

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. Add US1 (View) + US2 (Add) + US3 (Update) → Test independently → Deploy (Core MVP!)
3. Add US4 (Remove) → Test independently → Deploy
4. Add US5 (Add to Shopping List) → Test independently → Deploy
5. Add US6 (Purchased to Inventory) → Test independently → Deploy
6. Polish → Final release

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: US1 (View Inventory)
   - Developer B: US2 (Add Item)
   - Developer C: US3 (Update Quantity)
3. After US1-US3 merge:
   - Developer A: US4 (Remove Item)
   - Developer B: US5 (Add to Shopping List)
   - Developer C: US6 (Purchased to Inventory)
4. Team: Polish together

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- The existing `shopping_lists` feature (SPEC 005-006) is only modified in Phase 8 (US6)
