# Tasks: Invitations and Roles

**Input**: Design documents from `/specs/003-invitations-and-roles/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4, US5)
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: Create feature structure and base files

- [ ] T001 Create invitations feature directory structure at `lib/features/invitations/{data/{models,repositories},domain/{entities,usecases},presentation/{providers,screens,widgets}}`
- [ ] T002 [P] Create test directory structure at `test/unit/features/invitations/`, `test/integration/features/invitations/`, `test/widget/features/invitations/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T003 Create Invitation entity in `lib/features/invitations/domain/entities/invitation.dart`
- [ ] T004 [P] Create Role enum in `lib/features/invitations/domain/entities/role.dart`
- [ ] T005 [P] Create RolePermission entity in `lib/features/invitations/domain/entities/role_permission.dart`
- [ ] T006 Create InvitationModel in `lib/features/invitations/data/models/invitation_model.dart`
- [ ] T007 [P] Create RolePermissionModel in `lib/features/invitations/data/models/role_permission_model.dart`
- [ ] T008 Create InvitationRepository interface in `lib/features/invitations/data/repositories/invitation_repository.dart`
- [ ] T009 [P] Create RoleRepository interface in `lib/features/invitations/data/repositories/role_repository.dart`
- [ ] T010 Create InvitationsProvider in `lib/features/invitations/presentation/providers/invitations_provider.dart`
- [ ] T011 [P] Create RolesProvider in `lib/features/invitations/presentation/providers/roles_provider.dart`
- [ ] T012 Add Firebase FCM initialization to `lib/main.dart` (import firebase_core, initialize with DefaultFirebaseOptions)
- [ ] T013 Create NotificationService in `lib/core/services/notification_service.dart`
- [ ] T014 Run Supabase migration for invitations table with RLS policies
- [ ] T015 Run Supabase migration for role_permissions table with RLS policies
- [ ] T016 Create Supabase function send_invitation with validations
- [ ] T017 Create Supabase function accept_invitation with validations
- [ ] T018 Create Supabase function decline_invitation
- [ ] T019 Create Supabase function cancel_invitation
- [ ] T020 Create Supabase function change_member_role with validations
- [ ] T021 Create Supabase function remove_member with validations
- [ ] T022 Create Supabase function transfer_ownership with validations
- [ ] T023 Add Supabase Realtime subscription for invitations table

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Send Invitation to Join Home (Priority: P1) 🎯 MVP

**Goal**: Users can invite new members to their home by email

**Independent Test**: Send invitation, verify it appears in invitations list

### Implementation for User Story 1

- [ ] T024 [US1] Implement SendInvitationUseCase in `lib/features/invitations/domain/usecases/send_invitation_usecase.dart`
- [ ] T025 [US1] Implement sendInvitation method in InvitationRepository at `lib/features/invitations/data/repositories/invitation_repository.dart`
- [ ] T026 [P] [US1] Create SendInvitationScreen in `lib/features/invitations/presentation/screens/send_invitation_screen.dart`
- [ ] T027 [US1] Add email validation (required, valid format)
- [ ] T028 [US1] Add role selection dropdown (admin, member, viewer)
- [ ] T029 [US1] Add Arabic validation messages for invitation
- [ ] T030 [US1] Add loading state indicator during invitation send
- [ ] T031 [US1] Implement duplicate invitation check (FR-002)
- [ ] T032 [US1] Implement already member check (FR-002)
- [ ] T033 [US1] Send push notification to invitee via FCM (FR-012)
- [ ] T034 [US1] Log invitation activity to activity_logs (FR-011)
- [ ] T035 [US1] Show success message and redirect after invitation

**Checkpoint**: User Story 1 complete - users can send invitations

---

## Phase 4: User Story 2 - Receive and Accept Invitation (Priority: P1)

**Goal**: Users can receive invitations and accept/decline them

**Independent Test**: Receive invitation, accept it, verify membership

### Implementation for User Story 2

- [ ] T036 [US2] Implement AcceptInvitationUseCase in `lib/features/invitations/domain/usecases/accept_invitation_usecase.dart`
- [ ] T037 [P] [US2] Implement DeclineInvitationUseCase in `lib/features/invitations/domain/usecases/decline_invitation_usecase.dart`
- [ ] T038 [US2] Implement acceptInvitation method in InvitationRepository at `lib/features/invitations/data/repositories/invitation_repository.dart`
- [ ] T039 [P] [US2] Implement declineInvitation method in InvitationRepository at `lib/features/invitations/data/repositories/invitation_repository.dart`
- [ ] T040 [P] [US2] Create InvitationsListScreen in `lib/features/invitations/presentation/screens/invitations_list_screen.dart`
- [ ] T041 [US2] Create InvitationCardWidget in `lib/features/invitations/presentation/widgets/invitation_card_widget.dart`
- [ ] T042 [US2] Display home name, inviter name, and invitation date
- [ ] T043 [US2] Add accept/decline buttons to invitation card
- [ ] T044 [US2] Add empty state with Arabic instructions when no invitations
- [ ] T045 [US2] Add Realtime subscription for live invitation updates
- [ ] T046 [US2] Log acceptance/decline activity to activity_logs (FR-011)

**Checkpoint**: User Stories 1 AND 2 complete - full invitation flow

---

## Phase 5: User Story 3 - View and Manage Invitations (Priority: P2)

**Goal**: Home owners/admins can view and cancel pending invitations

**Independent Test**: View invitations list, cancel one

### Implementation for User Story 3

- [ ] T047 [US3] Implement CancelInvitationUseCase in `lib/features/invitations/domain/usecases/cancel_invitation_usecase.dart`
- [ ] T048 [US3] Implement cancelInvitation method in InvitationRepository at `lib/features/invitations/data/repositories/invitation_repository.dart`
- [ ] T049 [US3] Update InvitationsListScreen to show all home invitations for admins
- [ ] T050 [US3] Add cancel button to pending invitations
- [ ] T051 [US3] Add status filter (pending, accepted, declined, cancelled, expired)
- [ ] T052 [US3] Implement invitation expiry check (FR-013)
- [ ] T053 [US3] Log cancellation activity to activity_logs (FR-011)

**Checkpoint**: User Stories 1-3 complete - full invitation management

---

## Phase 6: User Story 4 - Assign and Change Member Roles (Priority: P2)

**Goal**: Home owners can assign and change member roles

**Independent Test**: Change member role, verify permissions update

### Implementation for User Story 4

- [ ] T054 [US4] Implement ChangeMemberRoleUseCase in `lib/features/invitations/domain/usecases/change_member_role_usecase.dart`
- [ ] T055 [US4] Implement changeMemberRole method in RoleRepository at `lib/features/invitations/data/repositories/role_repository.dart`
- [ ] T056 [P] [US4] Create ManageRolesScreen in `lib/features/invitations/presentation/screens/manage_roles_screen.dart`
- [ ] T057 [US4] Create RoleSelectorWidget in `lib/features/invitations/presentation/widgets/role_selector_widget.dart`
- [ ] T058 [US4] Display current role for each member
- [ ] T059 [US4] Add role change dropdown (owner can change all, admin can change member/viewer)
- [ ] T060 [US4] Implement owner protection (cannot demote owner) (FR-010)
- [ ] T061 [US4] Add Realtime subscription for role changes
- [ ] T062 [US4] Log role change activity to activity_logs (FR-011)
- [ ] T063 [US4] Update UI based on current user role permissions

**Checkpoint**: User Stories 1-4 complete - full role management

---

## Phase 7: User Story 5 - Remove Member from Home (Priority: P3)

**Goal**: Home owners/admins can remove members from home

**Independent Test**: Remove member, verify they lose access

### Implementation for User Story 5

- [ ] T064 [US5] Implement RemoveMemberUseCase in `lib/features/invitations/domain/usecases/remove_member_usecase.dart`
- [ ] T065 [US5] Implement TransferOwnershipUseCase in `lib/features/invitations/domain/usecases/transfer_ownership_usecase.dart`
- [ ] T066 [US5] Implement removeMember method in RoleRepository at `lib/features/invitations/data/repositories/role_repository.dart`
- [ ] T067 [P] [US5] Implement transferOwnership method in RoleRepository at `lib/features/invitations/data/repositories/role_repository.dart`
- [ ] T068 [US5] Add remove button to member card (owner/admin only)
- [ ] T069 [US5] Add confirmation dialog before removing member
- [ ] T070 [US5] Implement admin protection (only owner can remove admins)
- [ ] T071 [US5] Implement owner protection (cannot remove self, must transfer first)
- [ ] T072 [US5] Add transfer ownership flow in ManageRolesScreen
- [ ] T073 [US5] Log member removal and ownership transfer activities (FR-011)

**Checkpoint**: All user stories complete - full invitations and roles functionality

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] T074 [P] Add network error handling with retry for all invitation operations
- [ ] T075 [P] Add Arabic error messages for all invitation operations
- [ ] T076 Update home screen drawer with invitations navigation in `lib/features/home/presentation/screens/home_screen.dart`
- [ ] T077 Add invitation badge/count to home screen
- [ ] T078 Run `flutter analyze` and fix any issues
- [ ] T079 Run `flutter test` and ensure all tests pass

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-7)**: All depend on Foundational phase completion
  - US1 (Send Invitation) can start after foundational
  - US2 (Receive Invitation) can start after foundational
  - US3 (Manage Invitations) can start after US1 + US2
  - US4 (Manage Roles) can start after foundational
  - US5 (Remove Member) can start after US4
- **Polish (Phase 8)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2)
- **User Story 2 (P1)**: Can start after Foundational (Phase 2) - Can run in parallel with US1
- **User Story 3 (P2)**: Can start after US1 + US2 complete
- **User Story 4 (P2)**: Can start after Foundational (Phase 2) - Can run in parallel with US1/US2
- **User Story 5 (P3)**: Can start after US4 complete

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
- T011 can run in parallel with T010
- T026 can run in parallel with T024-T025
- T037 can run in parallel with T036
- T039 can run in parallel with T038
- T040 can run in parallel with T036-T039
- T056 can run in parallel with T054-T055
- T067 can run in parallel with T066
- T074, T075 can run in parallel

---

## Parallel Example: User Story 1

```bash
# Launch parallel tasks for User Story 1:
Task: "Create SendInvitationScreen in lib/features/invitations/presentation/screens/send_invitation_screen.dart"
# While these complete sequentially:
Task: "Implement SendInvitationUseCase in lib/features/invitations/domain/usecases/send_invitation_usecase.dart"
Task: "Implement sendInvitation method in InvitationRepository"
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 2 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 (Send Invitation)
4. Complete Phase 4: User Story 2 (Receive Invitation)
5. **STOP and VALIDATE**: Test invitation send and accept flow
6. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test invitation sending → Deploy/Demo
3. Add User Story 2 → Test invitation accept/decline → Deploy/Demo (MVP!)
4. Add User Story 3 → Test invitation management → Deploy/Demo
5. Add User Story 4 → Test role management → Deploy/Demo
6. Add User Story 5 → Test member removal → Deploy/Demo
7. Each story adds value without breaking previous stories

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Arabic RTL support must be verified for all UI tasks
- Database tables (invitations, role_permissions) need to be created before implementation
- Firebase FCM requires platform-specific setup (Android/iOS)
