# Tasks: Shopping Items

**Input**: Design documents from `/specs/006-shopping-items/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story. This feature enhances existing SPEC 05 code — no new entities or tables required.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup

**Purpose**: Verify existing codebase compiles and prepare for enhancements

- [x] T001 Verify existing shopping_lists feature compiles with `flutter analyze`
- [x] T002 Review existing provider, repository, and use case code in `lib/features/shopping_lists/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core provider and repository enhancements that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T003 Enhance ShoppingItemsState with groupedItems, filteredItems, searchQuery, filterCategoryId, lastDeletedItem, lastDeletedAt, unpurchasedTotal in `lib/features/shopping_lists/presentation/providers/shopping_items_provider.dart`
- [x] T004 Add getAutocompleteSuggestions method to ShoppingListRepository in `lib/features/shopping_lists/data/repositories/shopping_list_repository.dart`
- [x] T005 Implement getAutocompleteSuggestions in SupabaseShoppingListRepository — query item_templates + distinct shopping_items names with ILIKE in `lib/features/shopping_lists/data/repositories/supabase_shopping_list_repository.dart`
- [x] T006 Add syncTemplateOnAdd and incrementUsageCount methods to ItemTemplateRepository in `lib/features/shopping_lists/data/repositories/item_template_repository.dart`
- [x] T007 Implement syncTemplateOnAdd — check if template exists by (home_id, name), create or increment usage_count in `lib/features/shopping_lists/data/repositories/item_template_repository.dart`

**Checkpoint**: Foundation ready — user story implementation can now begin

---

## Phase 3: User Story 1 — Add Item to Shopping List (Priority: P1) 🎯 MVP

**Goal**: Users can add items with autocomplete suggestions, duplicate name warnings, and template auto-creation

**Independent Test**: Open a shopping list, add an item with name/quantity/unit, verify autocomplete shows suggestions with name+qty+unit, verify duplicate warning appears for existing names, verify template is created

### Implementation for User Story 1

- [x] T008 [US1] Add duplicate name check logic — query current list items by name, return AddItemResult.duplicateWarning if match found in `lib/features/shopping_lists/domain/usecases/add_item_usecase.dart`
- [x] T009 [US1] Add template sync call after successful item insert — call syncTemplateOnAdd in `lib/features/shopping_lists/domain/usecases/add_item_usecase.dart`
- [x] T010 [US1] Add addItem method with duplicate check return value and template sync in `lib/features/shopping_lists/presentation/providers/shopping_items_provider.dart`
- [x] T011 [P] [US1] Enhance item_suggestions_widget.dart to display name, quantity, and unit for each suggestion in `lib/features/shopping_lists/presentation/widgets/item_suggestions_widget.dart`
- [x] T012 [US1] Add duplicate warning dialog flow in add_item_screen.dart — show "Item already exists, add anyway?" snackbar, allow confirm or cancel in `lib/features/shopping_lists/presentation/screens/add_item_screen.dart`
- [x] T013 [US1] Integrate autocomplete suggestions into add_item_screen.dart name field in `lib/features/shopping_lists/presentation/screens/add_item_screen.dart`

**Checkpoint**: Adding items works with autocomplete, duplicate warnings, and template sync

---

## Phase 4: User Story 2 — Mark Items as Purchased (Priority: P1)

**Goal**: Users can toggle purchased status with visual feedback and real-time sync

**Independent Test**: Tap an item to mark purchased, verify strikethrough/checkmark, tap again to unmark, verify who purchased and when is displayed

### Implementation for User Story 2

- [x] T014 [US2] Update shopping_item_tile_widget.dart with purchased visual indicator — strikethrough text, checkmark icon, faded style for purchased items in `lib/features/shopping_lists/presentation/widgets/shopping_item_tile_widget.dart`
- [x] T015 [US2] Add purchased_by user name and purchased_at timestamp display in item tile in `lib/features/shopping_lists/presentation/widgets/shopping_item_tile_widget.dart`
- [x] T016 [US2] Ensure togglePurchased triggers real-time update visible to other members in `lib/features/shopping_lists/presentation/providers/shopping_items_provider.dart`

**Checkpoint**: Marking items as purchased works with visual feedback and real-time sync

---

## Phase 5: User Story 3 — Edit Item Details (Priority: P1)

**Goal**: Users can edit all item attributes without updating templates

**Independent Test**: Edit an item's name, quantity, unit, category, price, notes — verify changes save and sync, verify template is NOT modified

### Implementation for User Story 3

- [x] T017 [US3] Update update_item_usecase.dart to explicitly NOT call template sync on edit in `lib/features/shopping_lists/domain/usecases/update_item_usecase.dart`
- [x] T018 [US3] Add empty name validation in edit_item_screen.dart — prevent saving if name is cleared in `lib/features/shopping_lists/presentation/screens/edit_item_screen.dart`
- [x] T019 [US3] Ensure edit_item_screen.dart loads all current item attributes for editing in `lib/features/shopping_lists/presentation/screens/edit_item_screen.dart`

**Checkpoint**: Editing items works without affecting templates

---

## Phase 6: User Story 4 — Delete Items (Priority: P2)

**Goal**: Users can delete items with confirmation and 5-second undo window

**Independent Test**: Delete an item, verify confirmation prompt, verify undo snackbar appears for 5 seconds, verify undo restores the item

### Implementation for User Story 4

- [x] T020 [US4] Update delete_item_usecase.dart to store deleted item data for undo in `lib/features/shopping_lists/domain/usecases/delete_item_usecase.dart`
- [x] T021 [US4] Add undoDelete method with 5-second timer logic in `lib/features/shopping_lists/presentation/providers/shopping_items_provider.dart`
- [x] T022 [US4] Add undo delete snackbar with 5-second countdown in shopping_list_detail_screen.dart in `lib/features/shopping_lists/presentation/screens/shopping_list_detail_screen.dart`

**Checkpoint**: Delete with undo works

---

## Phase 7: User Story 5 — Search and Filter Items (Priority: P2)

**Goal**: Users can search by name and filter by category within a shopping list

**Independent Test**: Add multiple items, search by keyword, verify only matching items shown; filter by category, verify only that category shown; clear filters, verify all items shown

### Implementation for User Story 5

- [x] T023 [US5] Add searchItems method to get_shopping_items_usecase.dart — filter items by name query in `lib/features/shopping_lists/domain/usecases/get_shopping_items_usecase.dart`
- [x] T024 [US5] Implement setFilter and clearFilters methods with searchQuery and categoryId in `lib/features/shopping_lists/presentation/providers/shopping_items_provider.dart`
- [x] T025 [US5] Add search bar UI to shopping_list_detail_screen.dart — icon button that expands to text field in `lib/features/shopping_lists/presentation/screens/shopping_list_detail_screen.dart`
- [x] T026 [US5] Enhance category_filter_widget.dart with selectable category chips and clear button in `lib/features/shopping_lists/presentation/widgets/category_filter_widget.dart`

**Checkpoint**: Search and filter work within shopping lists

---

## Phase 8: User Story 6 — Organize Items by Category (Priority: P2)

**Goal**: Items are grouped under collapsible category headers with purchased items sinking to bottom

**Independent Test**: Add items with different categories, verify grouped display; collapse/expand groups; verify purchased items sink to bottom of each group; verify uncategorized items show under "Uncategorized"

### Implementation for User Story 6

- [x] T027 [US6] Implement groupedItems computation — group by category_id, sort unpurchased first within each group in `lib/features/shopping_lists/presentation/providers/shopping_items_provider.dart`
- [x] T028 [US6] Refactor shopping_list_detail_screen.dart to use grouped ListView with collapsible ExpansionTile per category; handle null category_id as "Uncategorized" group with localized label in `lib/features/shopping_lists/presentation/screens/shopping_list_detail_screen.dart`
- [x] T029 [P] [US6] Update shopping_item_tile_widget.dart to work correctly within grouped layout in `lib/features/shopping_lists/presentation/widgets/shopping_item_tile_widget.dart`

**Checkpoint**: Category grouping with collapsible headers and purchased sinking works

---

## Phase 9: User Story 7 — Quick-Add from Templates (Priority: P2)

**Goal**: Users can quickly add items from a template list sorted by usage count

**Independent Test**: Open Quick Add, verify templates sorted by usage count; select a template, verify item added with pre-filled details; verify empty state when no templates exist

### Implementation for User Story 7

- [x] T030 [US7] Enhance quick_add_screen.dart to sort templates by usage_count DESC in `lib/features/shopping_lists/presentation/screens/quick_add_screen.dart`
- [x] T031 [US7] Add empty state UI when no templates exist — prompt "Start adding items to build templates" in `lib/features/shopping_lists/presentation/screens/quick_add_screen.dart`
- [x] T032 [US7] Add incrementUsageCount call when template is selected in Quick Add in `lib/features/shopping_lists/presentation/screens/quick_add_screen.dart`

**Checkpoint**: Quick Add from templates works with usage count sorting and empty state

---

## Phase 10: User Story 8 — Track Item Prices (Priority: P3)

**Goal**: Users can optionally enter prices and see a running total of unpurchased items

**Independent Test**: Enter price for items, verify displayed on tile; verify running total at bottom of list; verify total only includes unpurchased items

### Implementation for User Story 8

- [x] T033 [US8] Add unpurchasedTotal computation — sum of price where is_purchased=false and price is not null in `lib/features/shopping_lists/presentation/providers/shopping_items_provider.dart`
- [x] T034 [US8] Add price display on shopping_item_tile_widget.dart in `lib/features/shopping_lists/presentation/widgets/shopping_item_tile_widget.dart`
- [x] T035 [US8] Add running total bar at bottom of shopping_list_detail_screen.dart showing unpurchased items total in `lib/features/shopping_lists/presentation/screens/shopping_list_detail_screen.dart`

**Checkpoint**: Price tracking with unpurchased-only total works

---

## Phase 11: User Story 9 — Auto-Create Templates (Priority: P3)

**Goal**: Templates are automatically created when items are added (not when edited)

**Independent Test**: Add an item, verify template created; add same item again, verify usage_count incremented; edit an item, verify template NOT modified

### Implementation for User Story 9

- [x] T036 [US9] Verify template behavior: confirm add_item_usecase.dart calls syncTemplateOnAdd and update_item_usecase.dart does NOT call template methods in `lib/features/shopping_lists/domain/usecases/`

**Checkpoint**: Template auto-create on add only works correctly

---

## Phase 12: Polish & Cross-Cutting Concerns

**Purpose**: Final quality checks and RTL verification

- [x] T037 [P] Verify Arabic RTL support on all enhanced widgets — category headers, search bar, filter chips, price total, undo snackbar
- [x] T038 Run `flutter analyze` and fix any issues
- [ ] T039 Verify app builds and runs on Android — test full add/edit/delete/purchase flow

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories
- **US1 (Phase 3)**: Depends on Foundational — core add flow
- **US2 (Phase 4)**: Depends on Foundational — can run in parallel with US1
- **US3 (Phase 5)**: Depends on Foundational — can run in parallel with US1/US2
- **US4 (Phase 6)**: Depends on Foundational — can run in parallel with US1-US3
- **US5 (Phase 7)**: Depends on Foundational — can run in parallel with US1-US4
- **US6 (Phase 8)**: Depends on Foundational + US1 (needs items to group) — can run in parallel with US5
- **US7 (Phase 9)**: Depends on Foundational — can run in parallel with US5/US6
- **US8 (Phase 10)**: Depends on Foundational — can run in parallel with US5-US7
- **US9 (Phase 11)**: Depends on US1 (template sync already in add_item_usecase) — verify only
- **Polish (Phase 12)**: Depends on all user stories complete

### User Story Dependencies

- **US1 (P1)**: Foundational → Add Item (core flow)
- **US2 (P1)**: Foundational → Mark Purchased (independent)
- **US3 (P1)**: Foundational → Edit Item (independent)
- **US4 (P2)**: Foundational → Delete with Undo (independent)
- **US5 (P2)**: Foundational → Search/Filter (independent)
- **US6 (P2)**: Foundational + US1 → Category Grouping (needs items in list)
- **US7 (P2)**: Foundational → Quick Add (independent)
- **US8 (P3)**: Foundational → Price Tracking (independent)
- **US9 (P3)**: US1 → Auto Templates (verify template sync behavior)

### Parallel Opportunities

- US1, US2, US3 can all proceed in parallel after Foundational (different files)
- US4, US5, US7, US8 can all proceed in parallel after Foundational
- T011 (item_suggestions_widget), T014-T015 (shopping_item_tile_widget), T026 (category_filter_widget), T029 (shopping_item_tile_widget grouped layout), T034 (price display) can run in parallel since they are different widget files

---

## Parallel Example: User Story 1

```bash
# Launch autocomplete widget enhancement and use case updates in parallel:
Task: "T011 [P] [US1] Enhance item_suggestions_widget.dart with name+qty+unit display"
Task: "T008 [US1] Add duplicate name check logic in add_item_usecase.dart"
Task: "T009 [US1] Add template sync call in add_item_usecase.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (provider state, repository methods)
3. Complete Phase 3: User Story 1 (Add Item with autocomplete + duplicate warning)
4. **STOP and VALIDATE**: Test adding items with autocomplete and duplicate warnings
5. Deploy/demo if ready

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. Add US1 (Add Item) → Test independently → MVP!
3. Add US2 (Mark Purchased) → Test independently
4. Add US3 (Edit Item) → Test independently
5. Add US4 (Delete with Undo) → Test independently
6. Add US5 (Search/Filter) + US6 (Category Grouping) + US7 (Quick Add) → Test independently
7. Add US8 (Price Tracking) + US9 (Auto Templates) → Test independently
8. Polish → Final validation

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- This feature enhances existing SPEC 05 code — no new entities or tables
- All Supabase tables and RLS policies already exist
- Real-time sync already configured in SPEC 05
- Arabic RTL support reuses existing bilingual text helper
