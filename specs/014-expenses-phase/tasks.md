# Tasks: Expenses Phase

**Input**: Design documents from `/specs/014-expenses-phase/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Tests are included as they are essential for financial data integrity.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Flutter app**: `lib/features/expenses/`, `test/features/expenses/`
- **Database**: Supabase migrations via `contracts/database.sql`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 Create feature directory structure at lib/features/expenses/ with data/, domain/, presentation/ subdirectories
- [x] T002 [P] Create test directory structure at test/features/expenses/ with data/, domain/, presentation/ subdirectories
- [ ] T003 Run database migration from contracts/database.sql to create expenses, expense_splits, settlements tables with RLS policies and RPC functions

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Create Expense entity in lib/features/expenses/domain/entities/expense.dart
- [x] T005 [P] Create ExpenseSplit entity in lib/features/expenses/domain/entities/expense_split.dart
- [x] T006 [P] Create Settlement entity in lib/features/expenses/domain/entities/settlement.dart
- [x] T007 [P] Create Balance entity in lib/features/expenses/domain/entities/balance.dart
- [x] T008 Create ExpenseRepository interface in lib/features/expenses/domain/repositories/expense_repository.dart
- [x] T009 [P] Create SettlementRepository interface in lib/features/expenses/domain/repositories/settlement_repository.dart
- [x] T010 Create ExpenseModel data class in lib/features/expenses/data/models/expense_model.dart
- [x] T011 [P] Create ExpenseSplitModel data class in lib/features/expenses/data/models/expense_split_model.dart
- [x] T012 [P] Create SettlementModel data class in lib/features/expenses/data/models/settlement_model.dart
- [x] T013 Create ExpenseRemoteDataSource in lib/features/expenses/data/datasources/expense_remote_datasource.dart
- [x] T014 [P] Create SettlementRemoteDataSource in lib/features/expenses/data/datasources/settlement_remote_datasource.dart
- [x] T015 Create ExpenseRepositoryImpl in lib/features/expenses/data/repositories/expense_repository_impl.dart
- [x] T016 [P] Create SettlementRepositoryImpl in lib/features/expenses/data/repositories/settlement_repository_impl.dart
- [x] T017 Create expense_providers (Riverpod) in lib/features/expenses/presentation/providers/expense_providers.dart
- [x] T018 [P] Create balance_providers (Riverpod) in lib/features/expenses/presentation/providers/balance_providers.dart

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Record an Expense (Priority: P1) 🎯 MVP

**Goal**: Allow home members to record expenses with amount, description, date, category, and optional shopping list item link

**Independent Test**: Add an expense with amount, description, and category, then verify it appears in the expense list

### Tests for User Story 1

- [x] T019 [P] [US1] Unit test for AddExpense use case in test/features/expenses/domain/usecases/add_expense_test.dart
- [x] T020 [P] [US1] Unit test for EditExpense use case in test/features/expenses/domain/usecases/edit_expense_test.dart
- [x] T021 [P] [US1] Unit test for DeleteExpense use case in test/features/expenses/domain/usecases/delete_expense_test.dart

### Implementation for User Story 1

- [x] T022 [US1] Create AddExpense use case in lib/features/expenses/domain/usecases/add_expense.dart
- [x] T023 [P] [US1] Create EditExpense use case in lib/features/expenses/domain/usecases/edit_expense.dart
- [x] T024 [P] [US1] Create DeleteExpense use case in lib/features/expenses/domain/usecases/delete_expense.dart
- [x] T025 [US1] Create AddExpenseScreen in lib/features/expenses/presentation/screens/add_expense_screen.dart
- [x] T026 [US1] Create ExpenseCard widget in lib/features/expenses/presentation/widgets/expense_card.dart
- [x] T027 [US1] Implement expense form with amount, description, date, category fields with RTL support
- [ ] T028 [US1] Add shopping list item selection to expense form

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - View Expense History (Priority: P1)

**Goal**: Display all expenses for a home with filtering by date range, category, and member

**Independent Test**: Add multiple expenses and verify they appear in a list sorted by date with totals and filters work correctly

### Tests for User Story 2

- [ ] T029 [P] [US2] Unit test for expense filtering by date range in test/features/expenses/domain/usecases/get_expenses_filtered_test.dart
- [ ] T030 [P] [US2] Widget test for ExpenseListScreen in test/features/expenses/presentation/screens/expense_list_screen_test.dart

### Implementation for User Story 2

- [x] T031 [US2] Create ExpenseListScreen in lib/features/expenses/presentation/screens/expense_list_screen.dart
- [ ] T032 [US2] Implement date range filter for expenses
- [ ] T033 [US2] Implement category filter for expenses
- [ ] T034 [US2] Implement member filter for expenses
- [ ] T035 [US2] Create empty state for expense list with instructions
- [ ] T036 [US2] Add expense total calculation and display

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - Split Expense Between Members (Priority: P1)

**Goal**: Allow expenses to be split equally or with custom amounts among selected home members

**Independent Test**: Create an expense split between 2+ members and verify each member's share is calculated correctly

### Tests for User Story 3

- [x] T037 [P] [US3] Unit test for equal split calculation in test/features/expenses/domain/usecases/split_expense_test.dart
- [x] T038 [P] [US3] Unit test for custom split calculation in test/features/expenses/domain/usecases/split_expense_test.dart
- [x] T039 [P] [US3] Unit test for rounding handling in test/features/expenses/domain/usecases/split_expense_test.dart

### Implementation for User Story 3

- [x] T040 [US3] Create SplitExpense use case in lib/features/expenses/domain/usecases/split_expense.dart
- [x] T041 [US3] Create SplitSelector widget in lib/features/expenses/presentation/widgets/split_selector.dart
- [x] T042 [US3] Implement equal split mode with member selection
- [x] T043 [US3] Implement custom split mode with amount per member
- [x] T044 [US3] Add split validation (sum must equal expense amount)
- [x] T045 [US3] Handle single-member split as personal expense (no split record)
- [x] T046 [US3] Implement rounding logic (remainder assigned to payer)
- [x] T047 [US3] Add split details view to ExpenseDetailScreen

**Checkpoint**: At this point, User Stories 1, 2, AND 3 should all work independently

---

## Phase 6: User Story 4 - Track Balances Between Members (Priority: P2)

**Goal**: Calculate and display net balances between all home members based on expense splits

**Independent Test**: Create multiple split expenses and verify the balance screen shows correct amounts owed between members

### Tests for User Story 4

- [ ] T048 [P] [US4] Unit test for CalculateBalances use case in test/features/expenses/domain/usecases/calculate_balances_test.dart
- [ ] T049 [P] [US4] Unit test for balance simplification (net amounts) in test/features/expenses/domain/usecases/balance_simplification_test.dart

### Implementation for User Story 4

- [x] T050 [US4] Create CalculateBalances use case in lib/features/expenses/domain/usecases/calculate_balances.dart
- [x] T051 [US4] Create BalancesScreen in lib/features/expenses/presentation/screens/balances_screen.dart
- [x] T052 [US4] Create BalanceCard widget in lib/features/expenses/presentation/widgets/balance_card.dart
- [x] T053 [US4] Implement "All settled up" empty state
- [x] T054 [US4] Integrate with Supabase RPC function calculate_home_balances

**Checkpoint**: Balance tracking is now functional

---

## Phase 7: User Story 5 - Record a Settlement (Priority: P2)

**Goal**: Allow members to record payments to settle debts, with support for partial and full settlements

**Independent Test**: Record a settlement between two members and verify the balance decreases accordingly

### Tests for User Story 5

- [ ] T055 [P] [US5] Unit test for RecordSettlement use case in test/features/expenses/domain/usecases/record_settlement_test.dart
- [ ] T056 [P] [US5] Unit test for partial settlement in test/features/expenses/domain/usecases/partial_settlement_test.dart

### Implementation for User Story 5

- [x] T057 [US5] Create RecordSettlement use case in lib/features/expenses/domain/usecases/record_settlement.dart
- [x] T058 [US5] Create SettlementForm widget in lib/features/expenses/presentation/widgets/settlement_form.dart
- [x] T059 [US5] Implement settlement recording with from/to member selection
- [x] T060 [US5] Add payment method selection (cash, transfer, other)
- [x] T061 [US5] Implement partial settlement support
- [x] T062 [US5] Update balances screen to show settlement history

**Checkpoint**: Settlement recording is now functional

---

## Phase 8: User Story 6 - View Expense Summary and Reports (Priority: P3)

**Goal**: Display spending summaries by category and time period with member contribution breakdown

**Independent Test**: View the summary screen with existing expenses and verify category breakdowns and totals display correctly

### Tests for User Story 6

- [ ] T063 [P] [US6] Unit test for GetExpenseSummary use case in test/features/expenses/domain/usecases/get_expense_summary_test.dart
- [ ] T064 [P] [US6] Widget test for ExpenseSummaryScreen in test/features/expenses/presentation/screens/expense_summary_screen_test.dart

### Implementation for User Story 6

- [x] T065 [US6] Create GetExpenseSummary use case in lib/features/expenses/domain/usecases/get_expense_summary.dart
- [x] T066 [US6] Create ExpenseSummaryScreen in lib/features/expenses/presentation/screens/expense_summary_screen.dart
- [ ] T067 [US6] Implement monthly total display
- [ ] T068 [US6] Implement time period selector (week, month, year, custom)
- [ ] T069 [US6] Implement category breakdown with amounts and percentages
- [ ] T070 [US6] Implement member contributions view

**Checkpoint**: All user stories are now complete

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] T071 [P] Add RTL support verification for all expense screens
- [ ] T072 [P] Implement realtime subscriptions for expense and settlement updates
- [x] T073 [P] Add expense detail screen (ExpenseDetailScreen) in lib/features/expenses/presentation/screens/expense_detail_screen.dart
- [ ] T074 Integrate expense feature with navigation (GoRouter routes)
- [ ] T075 Add member departure balance check (FR-019, FR-020)
- [ ] T076 Code cleanup and refactoring
- [ ] T077 Run quickstart.md validation
- [x] T078 Run flutter analyze and fix any issues

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-8)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Phase 9)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P1)**: Can start after Foundational (Phase 2) - Integrates with US1 for expense list
- **User Story 3 (P1)**: Can start after Foundational (Phase 2) - Integrates with US1 for expense splitting
- **User Story 4 (P2)**: Can start after Foundational (Phase 2) - Requires US3 (splits) for balance calculation
- **User Story 5 (P2)**: Can start after Foundational (Phase 2) - Integrates with US4 for settlements
- **User Story 6 (P3)**: Can start after Foundational (Phase 2) - Requires US1-US3 for summary data

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Models before services
- Services before UI
- Core implementation before integration
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- Once Foundational phase completes, US1, US2, US3 can start in parallel
- All tests for a user story marked [P] can run in parallel
- Models within a story marked [P] can run in parallel

---

## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together:
Task: "Unit test for AddExpense use case in test/features/expenses/domain/usecases/add_expense_test.dart"
Task: "Unit test for EditExpense use case in test/features/expenses/domain/usecases/edit_expense_test.dart"
Task: "Unit test for DeleteExpense use case in test/features/expenses/domain/usecases/delete_expense_test.dart"

# Launch all use cases for User Story 1 together (after tests fail):
Task: "Create AddExpense use case in lib/features/expenses/domain/usecases/add_expense.dart"
Task: "Create EditExpense use case in lib/features/expenses/domain/usecases/edit_expense.dart"
Task: "Create DeleteExpense use case in lib/features/expenses/domain/usecases/delete_expense.dart"
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
5. Add User Story 4 → Test independently → Deploy/Demo
6. Add User Story 5 → Test independently → Deploy/Demo
7. Add User Story 6 → Test independently → Deploy/Demo
8. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Stories 1, 2, 3 (P1 stories)
   - Developer B: User Stories 4, 5 (P2 stories)
   - Developer C: User Story 6 + Polish (P3 + final)
3. Stories complete and integrate independently

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
- All amounts stored in smallest currency unit (cents) as integers
- Soft delete uses deleted_at timestamp pattern
- Realtime subscriptions required for expense and settlement updates
