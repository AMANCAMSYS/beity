# Tasks: Auth and User Profile

**Input**: Design documents from `/specs/001-auth-user-profile/`  
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4)
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: Create feature structure and base files

- [x] T001 Create auth feature directory structure at `lib/features/auth/{data/{models,repositories},domain/{entities,usecases},presentation/{providers,screens}}`
- [x] T002 [P] Create test directory structure at `test/unit/features/auth/`, `test/integration/features/auth/`, `test/widget/features/auth/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T003 Create User entity in `lib/features/auth/domain/entities/user.dart`
- [x] T004 [P] Create UserModel in `lib/features/auth/data/models/user_model.dart`
- [x] T005 Create AuthRepository interface in `lib/features/auth/data/repositories/auth_repository.dart`
- [x] T006 [P] Create AuthErrorMessages utility in `lib/core/utils/auth_error_messages.dart`
- [x] T007 Create AuthProvider in `lib/features/auth/presentation/providers/auth_provider.dart`

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Register New Account (Priority: P1) 🎯 MVP

**Goal**: New users can create an account with email/password

**Independent Test**: Enter valid registration details and verify account is created, profile is saved, and user is redirected to home screen

### Implementation for User Story 1

- [x] T008 [US1] Implement SignUpUseCase in `lib/features/auth/domain/usecases/sign_up_usecase.dart`
- [x] T009 [US1] Implement signUp method in AuthRepository at `lib/features/auth/data/repositories/auth_repository.dart`
- [x] T010 [P] [US1] Create RegisterScreen in `lib/features/auth/presentation/screens/register_screen.dart`
- [x] T011 [US1] Add registration form validation (email format, password length, name required)
- [x] T012 [US1] Add Arabic error messages for registration (email already exists, weak password, invalid email)
- [x] T013 [US1] Add loading state indicator during registration
- [x] T014 [US1] Implement redirect to home screen after successful registration

**Checkpoint**: User Story 1 complete - users can register and are redirected to home

---

## Phase 4: User Story 2 - Login to Existing Account (Priority: P1)

**Goal**: Returning users can login with email/password

**Independent Test**: Enter valid credentials and verify user is authenticated and redirected to home screen

### Implementation for User Story 2

- [x] T015 [US2] Implement SignInUseCase in `lib/features/auth/domain/usecases/sign_in_usecase.dart`
- [x] T016 [US2] Implement signIn method in AuthRepository at `lib/features/auth/data/repositories/auth_repository.dart`
- [x] T017 [P] [US2] Create LoginScreen in `lib/features/auth/presentation/screens/login_screen.dart`
- [x] T018 [US2] Add login form validation (email format, password required)
- [x] T019 [US2] Add Arabic error messages for login (invalid credentials)
- [x] T020 [US2] Add loading state indicator during login
- [x] T021 [US2] Implement redirect to home screen after successful login
- [x] T022 [US2] Implement route guard to redirect unauthenticated users to login

**Checkpoint**: User Stories 1 AND 2 complete - users can register and login

---

## Phase 5: User Story 3 - Logout (Priority: P2)

**Goal**: Logged-in users can logout and end their session

**Independent Test**: Click logout and verify user is redirected to login screen and session is ended

### Implementation for User Story 3

- [x] T023 [US3] Implement SignOutUseCase in `lib/features/auth/domain/usecases/sign_out_usecase.dart`
- [x] T024 [US3] Implement signOut method in AuthRepository at `lib/features/auth/data/repositories/auth_repository.dart`
- [x] T025 [US3] Add logout button to home screen or profile
- [x] T026 [US3] Implement redirect to login screen after logout
- [x] T027 [US3] Verify session is ended after logout

**Checkpoint**: User Stories 1, 2, AND 3 complete - full auth flow works

---

## Phase 6: User Story 4 - View and Edit Profile (Priority: P2)

**Goal**: Users can view and edit their profile information

**Independent Test**: Navigate to profile, view info, edit name, verify changes are saved

### Implementation for User Story 4

- [x] T028 [US4] Implement UpdateProfileUseCase in `lib/features/auth/domain/usecases/update_profile_usecase.dart`
- [x] T029 [US4] Implement updateProfile method in AuthRepository at `lib/features/auth/data/repositories/auth_repository.dart`
- [x] T030 [P] [US4] Create ProfileScreen in `lib/features/auth/presentation/screens/profile_screen.dart`
- [x] T031 [US4] Display user profile information (name, email, phone, avatar)
- [x] T032 [US4] Add edit functionality for name and phone
- [x] T033 [US4] Make email field read-only
- [x] T034 [US4] Add Arabic validation messages for profile edit
- [x] T035 [US4] Add loading state during profile save
- [x] T036 [US4] Show success message after profile update

**Checkpoint**: All user stories complete - full auth and profile functionality

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T037 [P] Add network error handling with retry for all auth operations
- [x] T038 [P] Add session expiry handling with friendly Arabic message
- [x] T039 [P] Update router configuration with all auth routes in `lib/app/router/app_router.dart`
- [x] T040 Run `flutter analyze` and fix any issues
- [x] T041 Run `flutter test` and ensure all tests pass

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-6)**: All depend on Foundational phase completion
  - US1 (Register) and US2 (Login) can run in parallel after foundational
  - US3 (Logout) depends on US1 or US2 (need authenticated user)
  - US4 (Profile) depends on US2 (need authenticated user)
- **Polish (Phase 7)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2)
- **User Story 2 (P1)**: Can start after Foundational (Phase 2) - Can run in parallel with US1
- **User Story 3 (P2)**: Can start after US1 or US2 complete (needs authenticated user)
- **User Story 4 (P2)**: Can start after US2 complete (needs authenticated user)

### Within Each User Story

- Models/UseCases before Screens
- Repository methods before UseCases
- Core implementation before UI integration
- Story complete before moving to next priority

### Parallel Opportunities

- T002 can run in parallel with T001
- T004 can run in parallel with T003
- T006 can run in parallel with T005
- T010 can run in parallel with T008-T009
- T017 can run in parallel with T015-T016
- T030 can run in parallel with T028-T029
- T037, T038 can run in parallel

---

## Parallel Example: User Story 1

```bash
# Launch all parallel tasks for User Story 1:
Task: "Create RegisterScreen in lib/features/auth/presentation/screens/register_screen.dart"
# While these complete sequentially:
Task: "Implement SignUpUseCase in lib/features/auth/domain/usecases/sign_up_usecase.dart"
Task: "Implement signUp method in AuthRepository"
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 2 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 (Register)
4. Complete Phase 4: User Story 2 (Login)
5. **STOP and VALIDATE**: Test registration and login flow
6. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test registration → Deploy/Demo
3. Add User Story 2 → Test login → Deploy/Demo (MVP!)
4. Add User Story 3 → Test logout → Deploy/Demo
5. Add User Story 4 → Test profile → Deploy/Demo
6. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 (Register)
   - Developer B: User Story 2 (Login)
3. After US1 + US2 merge:
   - Developer A: User Story 3 (Logout)
   - Developer B: User Story 4 (Profile)

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Arabic RTL support must be verified for all UI tasks
