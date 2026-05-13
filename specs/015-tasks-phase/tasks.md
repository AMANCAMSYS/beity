# Tasks: Tasks Phase

**Input**: Design documents from `/specs/015-tasks-phase/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Feature code**: `lib/features/tasks/`
- **Tests**: `test/features/tasks/`
- **Database**: `supabase/migrations/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 Create feature directory structure under `lib/features/tasks/` with data/, domain/, and presentation/ subdirectories
- [x] T002 [P] Create domain entities in `lib/features/tasks/domain/entities/task.dart` and `lib/features/tasks/domain/entities/task_comment.dart`
- [x] T003 [P] Create repository interfaces in `lib/features/tasks/domain/repositories/task_repository.dart` and `lib/features/tasks/domain/repositories/task_comment_repository.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Create database migration with tasks and task_comments tables, RLS policies, indexes, and RPC functions in `supabase/migrations/20260513_add_tasks_tables.sql`
- [x] T005 [P] Create task model with JSON serialization in `lib/features/tasks/data/models/task_model.dart`
- [x] T006 [P] Create task comment model with JSON serialization in `lib/features/tasks/data/models/task_comment_model.dart`
- [x] T007 [P] Create task remote datasource with CRUD operations in `lib/features/tasks/data/datasources/task_remote_datasource.dart`
- [x] T008 [P] Create task comment remote datasource in `lib/features/tasks/data/datasources/task_comment_remote_datasource.dart`
- [x] T009 Implement task repository with datasource integration in `lib/features/tasks/data/repositories/task_repository_impl.dart`
- [x] T010 Implement task comment repository in `lib/features/tasks/data/repositories/task_comment_repository_impl.dart`
- [x] T011 Create task providers with Riverpod in `lib/features/tasks/presentation/providers/task_providers.dart`

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Create a Task (Priority: P1) 🎯 MVP

**Goal**: Home members can create tasks with title, description, due date, and category

**Independent Test**: Create a task with title, description, optional due date, and category; verify it appears in the task list

### Implementation for User Story 1

- [x] T012 [US1] Create CreateTask use case in `lib/features/tasks/domain/usecases/create_task.dart`
- [x] T013 [US1] Create add task screen with form fields (title, description, due date, category) in `lib/features/tasks/presentation/screens/add_task_screen.dart`
- [x] T014 [US1] Create task card widget displaying title, due date, and status in `lib/features/tasks/presentation/widgets/task_card.dart`

**Checkpoint**: Home members can create tasks that persist in the database

---

## Phase 4: User Story 4 - Complete a Task (Priority: P1)

**Goal**: Home members can mark tasks as complete/incomplete with timestamp tracking

**Independent Test**: Mark a task as complete, verify it shows completed status with timestamp and who completed it; mark as incomplete and verify reset

### Implementation for User Story 4

- [x] T015 [US4] Create CompleteTask use case in `lib/features/tasks/domain/usecases/complete_task.dart`
- [x] T016 [US4] Add complete/incomplete toggle to task detail screen in `lib/features/tasks/presentation/screens/task_detail_screen.dart`
- [x] T017 [US4] Update task card widget to show completion status, completed_by, and completed_at in `lib/features/tasks/presentation/widgets/task_card.dart`

**Checkpoint**: Tasks can be completed and uncompleted with proper tracking

---

## Phase 5: User Story 2 - View Task List (Priority: P1)

**Goal**: Tasks displayed in two tabs ("My Tasks" and "All Tasks") with proper sorting

**Independent Test**: Open tasks screen, verify "My Tasks" tab shows only assigned-to-me tasks, "All Tasks" tab shows all home tasks, incomplete tasks first, completed tasks at bottom

### Implementation for User Story 2

- [x] T018 [US2] Create GetTasks use case with tab filtering in `lib/features/tasks/domain/usecases/get_tasks.dart`
- [x] T019 [US2] Create task list screen with TabBar ("My Tasks", "All Tasks") in `lib/features/tasks/presentation/screens/task_list_screen.dart`
- [x] T020 [US2] Create task tabs widget managing tab state and queries in `lib/features/tasks/presentation/widgets/task_tabs.dart`
- [x] T021 [US2] Add empty state widget explaining how to create tasks when list is empty in `lib/features/tasks/presentation/screens/task_list_screen.dart`
- [x] T022 [US2] Add due date visual indicators (overdue, due today, upcoming) to task card in `lib/features/tasks/presentation/widgets/task_card.dart`
- [x] T023 [US2] Implement task list navigation in app router (GoRouter)

**Checkpoint**: Tasks are viewable in two tabs with proper sorting and visual indicators

---

## Phase 6: User Story 3 - Assign a Task to a Member (Priority: P1)

**Goal**: Tasks can be assigned to home members or left unassigned

**Independent Test**: Create/edit a task, assign to a member, verify they see it in "My Tasks" tab; reassign to different member and verify update

### Implementation for User Story 3

- [x] T024 [US3] Create AssignTask use case in `lib/features/tasks/domain/usecases/assign_task.dart`
- [x] T025 [US3] Add assignee picker to add/edit task screen showing home members list with "Unassigned" option in `lib/features/tasks/presentation/screens/add_task_screen.dart`
- [x] T026 [US3] Display assignee name on task card in `lib/features/tasks/presentation/widgets/task_card.dart`

**Checkpoint**: Tasks can be assigned and reassigned; "My Tasks" tab correctly filters

---

## Phase 7: User Story 5 - Set Recurring Tasks (Priority: P2)

**Goal**: Tasks can be set as recurring (daily/weekly/monthly) and auto-regenerate on completion

**Independent Test**: Create recurring task, complete it, verify new task instance is created with correct next due date

### Implementation for User Story 5

- [x] T027 [US5] Create ManageRecurrence use case in `lib/features/tasks/domain/usecases/manage_recurrence.dart`
- [x] T028 [US5] Create recurrence selector widget (daily/weekly/monthly/none) in `lib/features/tasks/presentation/widgets/recurrence_selector.dart`
- [x] T029 [US5] Add recurrence selector to add/edit task screen in `lib/features/tasks/presentation/screens/add_task_screen.dart`
- [x] T030 [US5] Update CompleteTask use case to call `create_next_recurring_task` RPC when task has recurrence in `lib/features/tasks/domain/usecases/complete_task.dart`
- [x] T031 [US5] Add recurrence indicator to task card showing recurrence type in `lib/features/tasks/presentation/widgets/task_card.dart`
- [x] T032 [US5] Add ability to disable recurrence (set recurrence_type to null) in edit task flow in `lib/features/tasks/presentation/screens/task_detail_screen.dart`

**Checkpoint**: Recurring tasks auto-regenerate on completion with correct due dates

---

## Phase 8: User Story 6 - Filter and Sort Tasks (Priority: P2)

**Goal**: Users can filter tasks by assignee, status, and due date; sort by due date and creation date

**Independent Test**: Apply various filters (assignee, status, due date) and verify only matching tasks shown; sort by due date and verify order

### Implementation for User Story 6

- [x] T033 [US6] Create task filter providers managing filter state in `lib/features/tasks/presentation/providers/task_filter_providers.dart`
- [x] T034 [US6] Create task filter bar widget with assignee, status, and due date filters in `lib/features/tasks/presentation/widgets/task_filter_bar.dart`
- [x] T035 [US6] Integrate filter bar into task list screen (both tabs) in `lib/features/tasks/presentation/screens/task_list_screen.dart`
- [x] T036 [US6] Add sort controls (by due date, by creation date) to task list screen in `lib/features/tasks/presentation/screens/task_list_screen.dart`
- [x] T037 [US6] Update GetTasks use case to support filter and sort parameters in `lib/features/tasks/domain/usecases/get_tasks.dart`

**Checkpoint**: Users can filter and sort tasks across both tabs

---

## Phase 9: User Story 7 - Add Comments to Tasks (Priority: P3)

**Goal**: Users can add and view comments on tasks in real-time

**Independent Test**: Add a comment to a task, verify it appears in chronological order with author and timestamp; verify real-time update for other members

### Implementation for User Story 7

- [x] T038 [US7] Create AddComment use case in `lib/features/tasks/domain/usecases/add_comment.dart`
- [x] T039 [US7] Create comment thread widget displaying comments chronologically with author name and timestamp in `lib/features/tasks/presentation/widgets/comment_thread.dart`
- [x] T040 [US7] Integrate comment thread into task detail screen in `lib/features/tasks/presentation/screens/task_detail_screen.dart`
- [x] T041 [US7] Add realtime subscription for task_comments in task detail screen in `lib/features/tasks/data/datasources/task_comment_remote_datasource.dart`

**Checkpoint**: Comments work on tasks with real-time sync

---

## Phase 10: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T042 [P] Implement EditTask use case with permission checks (creator/assignee/admin) in `lib/features/tasks/domain/usecases/edit_task.dart`
- [x] T043 [P] Implement ArchiveTask use case for soft-delete in `lib/features/tasks/domain/usecases/archive_task.dart`
- [x] T044 [P] Create archived tasks screen showing tasks completed > 7 days ago in `lib/features/tasks/presentation/screens/archived_tasks_screen.dart`
- [x] T045 [P] Add realtime subscription for tasks table in task list screen in `lib/features/tasks/data/datasources/task_remote_datasource.dart`
- [x] T046 Ensure all task screens support Arabic RTL layout
- [x] T047 Add edit task flow to task detail screen (title, description, due date, category) in `lib/features/tasks/presentation/screens/task_detail_screen.dart`
- [x] T048 Run quickstart.md validation checklist

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - US1 (Create Task) and US4 (Complete Task) can run in parallel after Phase 2
  - US2 (View List) depends on US1 being functional (needs tasks to display)
  - US3 (Assign) depends on US1 (needs tasks to assign)
  - US5 (Recurring) depends on US4 (extends completion flow)
  - US6 (Filter) depends on US2 (extends list view)
  - US7 (Comments) is independent after Phase 2
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 4 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P1)**: Can start after US1 (needs tasks to display)
- **User Story 3 (P1)**: Can start after US1 (needs tasks to assign)
- **User Story 5 (P2)**: Can start after US4 (extends completion with recurrence)
- **User Story 6 (P2)**: Can start after US2 (extends list with filters)
- **User Story 7 (P3)**: Can start after Foundational (Phase 2) - independent

### Within Each User Story

- Models before services
- Services before UI
- Core implementation before integration
- Story complete before moving to next priority

### Parallel Opportunities

- T002, T003 can run in parallel (different files)
- T005, T006 can run in parallel (different models)
- T007, T008 can run in parallel (different datasources)
- US1 and US4 can run in parallel after Phase 2
- US7 can run in parallel with US2-US6 after Phase 2
- T042, T043, T044, T045 can run in parallel (different files)

---

## Parallel Example: After Phase 2

```bash
# Launch US1 and US4 in parallel:
Task: "Create CreateTask use case in lib/features/tasks/domain/usecases/create_task.dart"
Task: "Create CompleteTask use case in lib/features/tasks/domain/usecases/complete_task.dart"

# Launch US7 in parallel with US2-US6:
Task: "Create AddComment use case in lib/features/tasks/domain/usecases/add_comment.dart"
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 4 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 (Create Task)
4. Complete Phase 4: User Story 4 (Complete Task)
5. **STOP and VALIDATE**: Create and complete tasks end-to-end
6. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add US1 + US4 → Test create/complete → Deploy/Demo (MVP!)
3. Add US2 → Test list view → Deploy/Demo
4. Add US3 → Test assignment → Deploy/Demo
5. Add US5 → Test recurrence → Deploy/Demo
6. Add US6 → Test filters → Deploy/Demo
7. Add US7 → Test comments → Deploy/Demo
8. Polish → Final release

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: US1 (Create Task) + US4 (Complete Task)
   - Developer B: US7 (Comments)
3. After US1 + US4:
   - Developer A: US2 (View List) + US3 (Assign)
   - Developer B: US5 (Recurring)
4. After US2:
   - Developer A: US6 (Filter & Sort)
   - Developer B: Polish phase

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
