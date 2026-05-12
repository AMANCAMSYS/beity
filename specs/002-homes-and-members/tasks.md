# Tasks: Homes and Members

**Input**: Design documents from `/specs/002-homes-and-members/`  
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4, US5)
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: Create feature structure and base files

- [x] T001 Create homes feature directory structure at `lib/features/homes/{data/{models,repositories},domain/{entities,usecases},presentation/{providers,screens,widgets}}`
- [x] T002 [P] Create test directory structure at `test/unit/features/homes/`, `test/integration/features/homes/`, `test/widget/features/homes/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T003 Create Home entity in `lib/features/homes/domain/entities/home.dart`
- [x] T004 [P] Create HomeMember entity in `lib/features/homes/domain/entities/home_member.dart`
- [x] T005 [P] Create HomeType enum in `lib/features/homes/domain/entities/home_type.dart`
- [x] T006 Create HomeModel in `lib/features/homes/data/models/home_model.dart`
- [x] T007 [P] Create HomeMemberModel in `lib/features/homes/data/models/home_member_model.dart`
- [x] T008 Create HomeRepository interface in `lib/features/homes/data/repositories/home_repository.dart`
- [x] T009 [P] Create HomeLocalDataSource for active home persistence in `lib/features/homes/data/repositories/home_local_data_source.dart`
- [x] T010 Create HomesProvider in `lib/features/homes/presentation/providers/homes_provider.dart`

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Create a New Home (Priority: P1) 🎯 MVP

**Goal**: Users can create a new home workspace and automatically become owner

**Independent Test**: Enter home name, select type, verify home is created with user as owner

### Implementation for User Story 1

- [x] T011 [US1] Implement CreateHomeUseCase in `lib/features/homes/domain/usecases/create_home_usecase.dart`
- [x] T012 [US1] Implement createHome method in HomeRepository at `lib/features/homes/data/repositories/home_repository.dart`
- [x] T013 [P] [US1] Create CreateHomeScreen in `lib/features/homes/presentation/screens/create_home_screen.dart`
- [x] T014 [US1] Add home name validation (required, 1-100 chars)
- [x] T015 [US1] Add home type selection (family, couple, shared_house, student_housing, single_user, office)
- [x] T016 [US1] Add Arabic validation messages for home creation
- [x] T017 [US1] Add loading state indicator during home creation
- [x] T018 [US1] Implement redirect to home after successful creation

**Checkpoint**: User Story 1 complete - users can create homes

---

## Phase 4: User Story 2 - View My Homes (Priority: P1)

**Goal**: Users can see all homes they belong to with member counts

**Independent Test**: Create multiple homes, verify all appear in homes list

### Implementation for User Story 2

- [x] T019 [US2] Implement GetUserHomesUseCase in `lib/features/homes/domain/usecases/get_user_homes_usecase.dart`
- [x] T020 [US2] Implement getUserHomes method in HomeRepository at `lib/features/homes/data/repositories/home_repository.dart`
- [x] T021 [P] [US2] Create HomesListScreen in `lib/features/homes/presentation/screens/homes_list_screen.dart`
- [x] T022 [US2] Create HomeCardWidget in `lib/features/homes/presentation/widgets/home_card_widget.dart`
- [x] T023 [US2] Display home name, type, and member count
- [x] T024 [US2] Add empty state with Arabic instructions when no homes
- [x] T025 [US2] Highlight active home in the list

**Checkpoint**: User Stories 1 AND 2 complete - users can create and view homes

---

## Phase 5: User Story 3 - Switch Active Home (Priority: P1)

**Goal**: Users can switch between homes they belong to

**Independent Test**: Switch homes, verify active home indicator changes

### Implementation for User Story 3

- [x] T026 [US3] Implement SwitchHomeUseCase in `lib/features/homes/domain/usecases/switch_home_usecase.dart`
- [x] T027 [US3] Implement setActiveHome in HomeLocalDataSource at `lib/features/homes/data/repositories/home_local_data_source.dart`
- [x] T028 [US3] Implement getActiveHome in HomeLocalDataSource at `lib/features/homes/data/repositories/home_local_data_source.dart`
- [x] T029 [US3] Add tap handler to HomeCardWidget for switching
- [x] T030 [US3] Update active home indicator in HomesListScreen
- [x] T031 [US3] Persist active home selection locally

**Checkpoint**: User Stories 1, 2, AND 3 complete - full home management

---

## Phase 6: User Story 4 - Mandatory Home Setup (Priority: P1)

**Goal**: New users must create or join a home on first login

**Independent Test**: Register new account, verify redirect to home setup screen

### Implementation for User Story 4

- [x] T032 [US4] Create OnboardingScreen in `lib/features/homes/presentation/screens/onboarding_screen.dart`
- [x] T033 [US4] Add hasHomes check to HomeRepository
- [x] T034 [US4] Update router redirect to check for homes in `lib/app/router/app_router.dart`
- [x] T035 [US4] Add "Create Home" button to onboarding screen
- [x] T036 [US4] Add "Join Home" placeholder to onboarding screen (invitation code input)
- [x] T037 [US4] Prevent navigation away from onboarding without a home

**Checkpoint**: User Stories 1-4 complete - full onboarding flow

---

## Phase 7: User Story 5 - View Home Members (Priority: P2)

**Goal**: Users can view members of their current home

**Independent Test**: View members list for a home with multiple members

### Implementation for User Story 5

- [x] T038 [US5] Implement GetHomeMembersUseCase in `lib/features/homes/domain/usecases/get_home_members_usecase.dart`
- [x] T039 [US5] Implement getHomeMembers method in HomeRepository at `lib/features/homes/data/repositories/home_repository.dart`
- [x] T040 [P] [US5] Create HomeMembersScreen in `lib/features/homes/presentation/screens/home_members_screen.dart`
- [x] T041 [US5] Create MemberCardWidget in `lib/features/homes/presentation/widgets/member_card_widget.dart`
- [x] T042 [US5] Display member name, role, and join date
- [x] T043 [US5] Highlight owner role with badge or icon
- [x] T044 [US5] Add navigation to members screen from home screen

**Checkpoint**: All user stories complete - full homes and members functionality

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T045 [P] Add network error handling with retry for all home operations
- [x] T046 [P] Add Arabic error messages for all home operations
- [x] T047 Update home screen drawer with homes navigation in `lib/features/home/presentation/screens/home_screen.dart`
- [x] T048 Run `flutter analyze` and fix any issues
- [x] T049 Run `flutter test` and ensure all tests pass

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-7)**: All depend on Foundational phase completion
  - US1 (Create Home) can start after foundational
  - US2 (View Homes) can start after foundational
  - US3 (Switch Home) depends on US1 + US2
  - US4 (Onboarding) depends on US1 + US2
  - US5 (View Members) depends on US1
- **Polish (Phase 8)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2)
- **User Story 2 (P1)**: Can start after Foundational (Phase 2) - Can run in parallel with US1
- **User Story 3 (P1)**: Can start after US1 + US2 complete
- **User Story 4 (P1)**: Can start after US1 + US2 complete
- **User Story 5 (P2)**: Can start after US1 complete

### Within Each User Story

- Models/UseCases before Screens
- Repository methods before UseCases
- Core implementation before UI integration
- Story complete before moving to next priority

### Parallel Opportunities

- T002 can run in parallel with T001
- T004, T005 can run in parallel with T003
- T007 can run in parallel with T006
- T009 can run in parallel with T008
- T013 can run in parallel with T011-T012
- T021 can run in parallel with T019-T020
- T040 can run in parallel with T038-T039
- T045, T046 can run in parallel

---

## Parallel Example: User Story 1

```bash
# Launch parallel tasks for User Story 1:
Task: "Create CreateHomeScreen in lib/features/homes/presentation/screens/create_home_screen.dart"
# While these complete sequentially:
Task: "Implement CreateHomeUseCase in lib/features/homes/domain/usecases/create_home_usecase.dart"
Task: "Implement createHome method in HomeRepository"
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 2 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 (Create Home)
4. Complete Phase 4: User Story 2 (View Homes)
5. **STOP and VALIDATE**: Test home creation and listing
6. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test home creation → Deploy/Demo
3. Add User Story 2 → Test home listing → Deploy/Demo (MVP!)
4. Add User Story 3 → Test home switching → Deploy/Demo
5. Add User Story 4 → Test onboarding → Deploy/Demo
6. Add User Story 5 → Test member viewing → Deploy/Demo
7. Each story adds value without breaking previous stories

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Arabic RTL support must be verified for all UI tasks
- Database tables (homes, home_members) already exist from initial setup
