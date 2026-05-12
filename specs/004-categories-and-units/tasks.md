# Tasks: Categories and Units

**Input**: Design documents from `/specs/004-categories-and-units/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4, US5)
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: Create feature structure and base files

- [ ] T001 Create categories feature directory structure at `lib/features/categories/{data/{models,repositories},domain/{entities,usecases},presentation/{providers,screens,widgets}}`
- [ ] T002 [P] Create test directory structure at `test/unit/features/categories/`, `test/integration/features/categories/`, `test/widget/features/categories/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T003 Create Category entity in `lib/features/categories/domain/entities/category.dart`
- [ ] T004 [P] Create Unit entity in `lib/features/categories/domain/entities/unit.dart`
- [ ] T005 Create CategoryModel in `lib/features/categories/data/models/category_model.dart`
- [ ] T006 [P] Create UnitModel in `lib/features/categories/data/models/unit_model.dart`
- [ ] T007 Create CategoryRepository interface in `lib/features/categories/data/repositories/category_repository.dart`
- [ ] T008 [P] Create UnitRepository interface in `lib/features/categories/data/repositories/unit_repository.dart`
- [ ] T009 Create CategoriesProvider in `lib/features/categories/presentation/providers/categories_provider.dart`
- [ ] T010 [P] Create UnitsProvider in `lib/features/categories/presentation/providers/units_provider.dart`
- [ ] T011 Create BilingualTextHelper in `lib/core/utils/bilingual_text_helper.dart`
- [ ] T012 Run Supabase migration for categories table with RLS policies
- [ ] T013 Run Supabase migration for units table with RLS policies
- [ ] T014 Insert default categories data (8 categories)
- [ ] T015 Insert default units data (11 units)

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - View Categories (Priority: P1) 🎯 MVP

**Goal**: Users can view available categories when creating or editing products

**Independent Test**: View categories list, verify all default categories appear

### Implementation for User Story 1

- [ ] T016 [US1] Implement GetCategoriesUseCase in `lib/features/categories/domain/usecases/get_categories_usecase.dart`
- [ ] T017 [US1] Implement getCategories method in CategoryRepository at `lib/features/categories/data/repositories/category_repository.dart`
- [ ] T018 [P] [US1] Create CategoriesListScreen in `lib/features/categories/presentation/screens/categories_list_screen.dart`
- [ ] T019 [US1] Create CategoryCardWidget in `lib/features/categories/presentation/widgets/category_card_widget.dart`
- [ ] T020 [US1] Display category name (Arabic/English with fallback), icon, and color
- [ ] T021 [US1] Add category type filter (shopping, inventory, expense)
- [ ] T022 [US1] Add empty state with Arabic instructions when no categories
- [ ] T023 [US1] Add Realtime subscription for live category updates

**Checkpoint**: User Story 1 complete - users can view categories

---

## Phase 4: User Story 4 - View Units (Priority: P1)

**Goal**: Users can view available units when creating or editing products

**Independent Test**: View units list, verify all default units appear

### Implementation for User Story 4

- [ ] T024 [US4] Implement GetUnitsUseCase in `lib/features/categories/domain/usecases/get_units_usecase.dart`
- [ ] T025 [US4] Implement getUnits method in UnitRepository at `lib/features/categories/data/repositories/unit_repository.dart`
- [ ] T026 [P] [US4] Create UnitsListScreen in `lib/features/categories/presentation/screens/units_list_screen.dart`
- [ ] T027 [US4] Create UnitCardWidget in `lib/features/categories/presentation/widgets/unit_card_widget.dart`
- [ ] T028 [US4] Display unit name (Arabic/English with fallback), symbol, and type
- [ ] T029 [US4] Add unit type filter (weight, volume, count, length)
- [ ] T030 [US4] Add empty state with Arabic instructions when no units
- [ ] T031 [US4] Add Realtime subscription for live unit updates

**Checkpoint**: User Stories 1 AND 4 complete - users can view categories and units

---

## Phase 5: User Story 2 - Create Custom Categories (Priority: P2)

**Goal**: Home owners/admins can create custom categories for their homes

**Independent Test**: Create custom category, verify it appears in categories list

### Implementation for User Story 2

- [ ] T032 [US2] Implement CreateCategoryUseCase in `lib/features/categories/domain/usecases/create_category_usecase.dart`
- [ ] T033 [US2] Implement createCategory method in CategoryRepository at `lib/features/categories/data/repositories/category_repository.dart`
- [ ] T034 [P] [US2] Create CreateCategoryScreen in `lib/features/categories/presentation/screens/create_category_screen.dart`
- [ ] T035 [US2] Add Arabic name validation (required, unique within home)
- [ ] T036 [US2] Add English name validation (optional, unique within home if provided)
- [ ] T037 [US2] Add category type selection (shopping, inventory, expense)
- [ ] T038 [US2] Add icon picker (optional)
- [ ] T039 [US2] Add color picker (optional)
- [ ] T040 [US2] Add Arabic validation messages for category creation
- [ ] T041 [US2] Add loading state indicator during category creation
- [ ] T042 [US2] Implement duplicate name check (FR-003)
- [ ] T043 [US2] Log category creation activity to activity_logs
- [ ] T044 [US2] Show success message and redirect after category creation

**Checkpoint**: User Stories 1, 2, AND 4 complete - users can view and create categories

---

## Phase 6: User Story 3 - Edit and Delete Custom Categories (Priority: P2)

**Goal**: Home owners/admins can edit or delete custom categories

**Independent Test**: Edit category name, verify change persists; delete category, verify products become uncategorized

### Implementation for User Story 3

- [ ] T045 [US3] Implement UpdateCategoryUseCase in `lib/features/categories/domain/usecases/update_category_usecase.dart`
- [ ] T046 [P] [US3] Implement DeleteCategoryUseCase in `lib/features/categories/domain/usecases/delete_category_usecase.dart`
- [ ] T047 [US3] Implement updateCategory method in CategoryRepository at `lib/features/categories/data/repositories/category_repository.dart`
- [ ] T048 [P] [US3] Implement deleteCategory method in CategoryRepository at `lib/features/categories/data/repositories/category_repository.dart`
- [ ] T049 [US3] Add edit button to category card (owner/admin only, not for defaults)
- [ ] T050 [US3] Add delete button to category card (owner/admin only, not for defaults)
- [ ] T051 [US3] Add confirmation dialog before deleting category
- [ ] T052 [US3] Warn when deleting category that has products (FR-007)
- [ ] T053 [US3] Implement default category protection (FR-005)
- [ ] T054 [US3] Log category update/delete activity to activity_logs

**Checkpoint**: User Stories 1-4 complete - full category management

---

## Phase 7: User Story 5 - Create Custom Units (Priority: P3)

**Goal**: Home owners/admins can create custom units for their homes

**Independent Test**: Create custom unit, verify it appears in units list

### Implementation for User Story 5

- [ ] T055 [US5] Implement CreateUnitUseCase in `lib/features/categories/domain/usecases/create_unit_usecase.dart`
- [ ] T056 [US5] Implement createUnit method in UnitRepository at `lib/features/categories/data/repositories/unit_repository.dart`
- [ ] T057 [P] [US5] Create CreateUnitScreen in `lib/features/categories/presentation/screens/create_unit_screen.dart`
- [ ] T058 [US5] Add Arabic name validation (required, unique within home)
- [ ] T059 [US5] Add English name validation (optional, unique within home if provided)
- [ ] T060 [US5] Add symbol validation (required, unique within home)
- [ ] T061 [US5] Add unit type selection (weight, volume, count, length)
- [ ] T062 [US5] Add Arabic validation messages for unit creation
- [ ] T063 [US5] Add loading state indicator during unit creation
- [ ] T064 [US5] Implement duplicate name/symbol check (FR-010)
- [ ] T065 [US5] Log unit creation activity to activity_logs
- [ ] T066 [US5] Show success message and redirect after unit creation

**Checkpoint**: All user stories complete - full categories and units functionality

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] T067 [P] Add network error handling with retry for all category/unit operations
- [ ] T068 [P] Add Arabic error messages for all category/unit operations
- [ ] T069 Update home screen drawer with categories navigation in `lib/features/home/presentation/screens/home_screen.dart`
- [ ] T070 Update home screen drawer with units navigation in `lib/features/home/presentation/screens/home_screen.dart`
- [ ] T071 Run `flutter analyze` and fix any issues
- [ ] T072 Run `flutter test` and ensure all tests pass

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-7)**: All depend on Foundational phase completion
  - US1 (View Categories) can start after foundational
  - US4 (View Units) can start after foundational - Can run in parallel with US1
  - US2 (Create Categories) can start after US1
  - US3 (Edit/Delete Categories) can start after US2
  - US5 (Create Units) can start after US4
- **Polish (Phase 8)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2)
- **User Story 4 (P1)**: Can start after Foundational (Phase 2) - Can run in parallel with US1
- **User Story 2 (P2)**: Can start after US1 complete
- **User Story 3 (P2)**: Can start after US2 complete
- **User Story 5 (P3)**: Can start after US4 complete

### Within Each User Story

- Models/UseCases before Screens
- Repository methods before UseCases
- Core implementation before UI integration
- Story complete before moving to next priority

### Parallel Opportunities

- T002 can run in parallel with T001
- T004 can run in parallel with T003
- T006 can run in parallel with T005
- T008 can run in parallel with T007
- T010 can run in parallel with T009
- T018 can run in parallel with T016-T017
- T026 can run in parallel with T024-T025
- T034 can run in parallel with T032-T033
- T046 can run in parallel with T045
- T048 can run in parallel with T047
- T057 can run in parallel with T055-T056
- T067, T068 can run in parallel

---

## Parallel Example: User Story 1

```bash
# Launch parallel tasks for User Story 1:
Task: "Create CategoriesListScreen in lib/features/categories/presentation/screens/categories_list_screen.dart"
# While these complete sequentially:
Task: "Implement GetCategoriesUseCase in lib/features/categories/domain/usecases/get_categories_usecase.dart"
Task: "Implement getCategories method in CategoryRepository"
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 4 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 (View Categories)
4. Complete Phase 4: User Story 4 (View Units)
5. **STOP and VALIDATE**: Test categories and units viewing
6. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test category viewing → Deploy/Demo
3. Add User Story 4 → Test unit viewing → Deploy/Demo (MVP!)
4. Add User Story 2 → Test category creation → Deploy/Demo
5. Add User Story 3 → Test category edit/delete → Deploy/Demo
6. Add User Story 5 → Test unit creation → Deploy/Demo
7. Each story adds value without breaking previous stories

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Arabic RTL support must be verified for all UI tasks
- Bilingual support (name_ar, name_en) must be implemented for all entities
- Database tables (categories, units) need to be created before implementation
- Default data must be inserted for categories and units
