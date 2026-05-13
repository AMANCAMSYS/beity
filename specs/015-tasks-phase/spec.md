# Feature Specification: Tasks Phase

**Feature Branch**: `015-tasks-phase`  
**Created**: 2026-05-13  
**Status**: Draft  
**Input**: User description: "SPEC 15 — Tasks Phase"

## Clarifications

### Session 2026-05-13

- Q: Who should be allowed to edit a task? → A: Creator, assignee, and home admin can edit.
- Q: Which recurrence patterns should be supported? → A: Daily, weekly, monthly only (simplest). Weekly repeats every 7 days from task creation; monthly repeats on the same calendar day.
- Q: Should the task list have tabs or a single list with filters? → A: Two tabs — "My Tasks" (tasks assigned to current user) and "All Tasks" — with additional filters available on both.
- Q: How long should completed tasks remain visible in the active task list? → A: Completed tasks stay visible for 7 days, then are automatically archived. Archived tasks are accessible via a separate "Archived" view.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Create a Task (Priority: P1)

As a home member, I want to create a household task so that everyone in the home knows what needs to be done.

**Why this priority**: Creating tasks is the foundation of the tasks feature. Without the ability to create tasks, no other task functionality delivers value.

**Independent Test**: Can be fully tested by creating a task with a title, description, and optional due date, then verifying it appears in the task list.

**Acceptance Scenarios**:

1. **Given** I am a member of a home, **When** I tap "Add Task" and enter a title, **Then** the task is saved and visible to all home members
2. **Given** I am creating a task, **When** I add a description, **Then** the description is saved with the task
3. **Given** I am creating a task, **When** I set a due date, **Then** the task displays the due date
4. **Given** I am creating a task, **When** I leave the due date unset, **Then** the task has no due date and is treated as ongoing
5. **Given** I am creating a task, **When** I select a category, **Then** the task is saved under that category

---

### User Story 2 - View Task List (Priority: P1)

As a home member, I want to see tasks for my home organized into "My Tasks" and "All Tasks" tabs so that I can quickly see what's assigned to me versus the full household picture.

**Why this priority**: Viewing the task list is the primary way members stay informed about household responsibilities. Tab structure reduces taps for the most common use case.

**Independent Test**: Can be tested by opening the tasks screen and verifying two tabs exist: "My Tasks" showing assigned-to-me tasks, "All Tasks" showing all home tasks.

**Acceptance Scenarios**:

1. **Given** my home has tasks, **When** I open the tasks screen, **Then** I see two tabs: "My Tasks" and "All Tasks"
2. **Given** I am on the "My Tasks" tab, **When** tasks are assigned to me, **Then** I see only tasks assigned to me
3. **Given** I am on the "All Tasks" tab, **When** tasks exist, **Then** I see all tasks for the home with title, assignee, due date, and completion status
4. **Given** tasks exist with different statuses, **When** I view either tab, **Then** incomplete tasks appear first and completed tasks (within 7 days) appear at the bottom
5. **Given** a task has a due date, **When** I view the task, **Then** the due date is displayed with visual indicators for overdue and due-today tasks
6. **Given** tasks were completed more than 7 days ago, **When** I view the task list, **Then** they are not shown in the active list but are accessible via an "Archived" view
7. **Given** the home has no tasks, **When** I open the tasks screen, **Then** I see an empty state explaining how to create tasks

---

### User Story 3 - Assign a Task to a Member (Priority: P1)

As a home member, I want to assign a task to a specific home member so that responsibilities are clear.

**Why this priority**: Assignment is essential for shared accountability — without it, tasks are just a generic list with no ownership.

**Independent Test**: Can be tested by creating a task, assigning it to a member, and verifying the assignee sees it in their task view.

**Acceptance Scenarios**:

1. **Given** I am creating or editing a task, **When** I select a home member as the assignee, **Then** the task is assigned to that member
2. **Given** a task is assigned to me, **When** I view the task list, **Then** I can filter to see only my tasks
3. **Given** a task is assigned to another member, **When** that member opens the app, **Then** they see the task in their assigned tasks
4. **Given** I am assigning a task, **When** I select "Unassigned", **Then** the task has no assignee and is visible to all members
5. **Given** I assign a task, **When** I reassign it to a different member, **Then** the assignment updates and both members see the change

---

### User Story 4 - Complete a Task (Priority: P1)

As a home member, I want to mark a task as complete so that everyone knows it has been done.

**Why this priority**: Completing tasks is the core action that drives the task lifecycle and provides a sense of progress.

**Independent Test**: Can be tested by marking a task as complete and verifying it shows as completed with a timestamp and who completed it.

**Acceptance Scenarios**:

1. **Given** I am viewing an incomplete task, **When** I mark it as complete, **Then** the task shows as completed with a completion timestamp
2. **Given** I complete a task, **When** other members view the task list, **Then** they see the task marked as completed by me
3. **Given** a task is completed, **When** I view the task details, **Then** I see who completed it and when
4. **Given** a completed task, **When** I mark it as incomplete, **Then** the task returns to its previous incomplete state

---

### User Story 5 - Set Recurring Tasks (Priority: P2)

As a home member, I want to create recurring tasks that automatically regenerate after completion so that repeated chores are tracked without manual re-creation.

**Why this priority**: Many household tasks repeat daily, weekly, or monthly. Recurrence automation reduces manual effort and ensures nothing is forgotten.

**Independent Test**: Can be tested by creating a recurring task, completing it, and verifying a new task instance is generated with the next due date.

**Acceptance Scenarios**:

1. **Given** I am creating a task, **When** I set a recurrence pattern (daily, weekly, monthly), **Then** the task is marked as recurring
2. **Given** a recurring task is completed, **When** the system processes the completion, **Then** a new task instance is created with the next due date: daily (+1 day), weekly (+7 days), monthly (same calendar day next month)
3. **Given** a recurring task has no due date, **When** it is completed, **Then** a new instance is created with a due date calculated from the completion date using the recurrence interval
4. **Given** I want to stop a recurring task, **When** I disable recurrence on the task, **Then** no new instances are generated after the current one is completed

---

### User Story 6 - Filter and Sort Tasks (Priority: P2)

As a home member, I want to filter and sort tasks so that I can quickly find what matters to me.

**Why this priority**: As the number of tasks grows, filtering becomes essential for usability.

**Independent Test**: Can be tested by applying various filters (assignee, status, due date) and verifying only matching tasks are shown.

**Acceptance Scenarios**:

1. **Given** tasks exist assigned to different members, **When** I filter by assignee, **Then** only tasks assigned to that member are shown
2. **Given** tasks exist with different statuses, **When** I filter by status, **Then** only tasks with that status are shown
3. **Given** tasks exist with various due dates, **When** I filter by "Due today", **Then** only tasks due today are shown
4. **Given** tasks exist with various due dates, **When** I sort by due date, **Then** tasks are ordered from soonest to latest
5. **Given** I have active filters, **When** I clear filters, **Then** all tasks are shown again

---

### User Story 7 - Add Comments to Tasks (Priority: P3)

As a home member, I want to add comments to a task so that I can communicate about the task with other members.

**Why this priority**: Comments enable coordination around tasks but are not essential for the core task management flow.

**Independent Test**: Can be tested by adding a comment to a task and verifying it appears in the task's comment thread.

**Acceptance Scenarios**:

1. **Given** I am viewing a task, **When** I add a comment, **Then** the comment appears in the task's comment thread with my name and timestamp
2. **Given** a task has comments, **When** I view the task, **Then** I see all comments in chronological order
3. **Given** another member adds a comment, **When** I view the task, **Then** I see the new comment in real-time

---

### Edge Cases

- What happens when a member leaves a home with tasks assigned to them? → Tasks become unassigned; other members can reassign them.
- How does the system handle a recurring task whose due date falls on a day with no valid date (e.g., 31st of a 30-day month)? → The system uses the last day of that month.
- What happens when two members complete the same task simultaneously? → First write wins; second completion is rejected with a message that the task is already completed.
- What happens when a task is deleted? → Task is soft-deleted (archived) and removed from active views but preserved for history.
- What happens when a home is deleted? → All tasks for that home are cascade-deleted.
- How does the system handle tasks with extremely long titles or descriptions? → Titles are capped at 200 characters, descriptions at 2000 characters.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow home members to create tasks with a title (required) and optional description, due date, category, and assignee
- **FR-002**: System MUST display tasks in two tabs: "My Tasks" (assigned to current user) and "All Tasks" (all home tasks), with filtering available on both
- **FR-003**: System MUST allow assigning a task to any home member or leaving it unassigned
- **FR-004**: System MUST allow any home member to mark a task as complete or incomplete
- **FR-005**: System MUST record who completed a task and when
- **FR-006**: System MUST visually distinguish overdue tasks, tasks due today, and upcoming tasks
- **FR-007**: System MUST support recurring tasks with patterns: daily, weekly, monthly
- **FR-008**: System MUST automatically create a new task instance when a recurring task is completed
- **FR-009**: System MUST allow filtering tasks by assignee, status (complete/incomplete), and due date (today, this week, overdue)
- **FR-010**: System MUST allow sorting tasks by due date and creation date
- **FR-011**: System MUST allow the task creator, assignee, or home admin to reassign a task to a different member
- **FR-012**: System MUST allow only the task creator, assignee, or home admin to edit a task's title, description, due date, and category
- **FR-013**: System MUST allow soft-deleting (archiving) tasks, removing them from active views
- **FR-013a**: System MUST automatically archive completed tasks after 7 days, moving them out of the active list into an "Archived" view
- **FR-014**: System MUST sync task changes to all home members in real-time
- **FR-015**: System MUST enforce home membership: only members of a home can view or modify that home's tasks
- **FR-016**: System MUST track who created each task
- **FR-017**: System MUST support Arabic (RTL) and English (LTR) layouts for all task screens
- **FR-018**: System MUST display an informative empty state when no tasks exist
- **FR-019**: System MUST allow members to add comments to tasks
- **FR-020**: System MUST display task comments in chronological order with author and timestamp
- **FR-021**: System MUST cap task titles at 200 characters and descriptions at 2000 characters
- **FR-022**: System MUST allow disabling recurrence on a recurring task

### Key Entities

- **Task**: Represents a household task or chore. Key attributes: title, description, due date, category, assignee, status (incomplete/completed), recurrence pattern, home reference, created/updated metadata, completed by, completed at.
- **Task Comment**: Represents a message on a task. Key attributes: task reference, author, content, timestamp.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can create a task in under 15 seconds
- **SC-002**: Users can view their home's task list with less than 2 seconds load time
- **SC-003**: 90% of users successfully create and assign their first task without needing help
- **SC-004**: Task completion actions sync to all home members within 2 seconds
- **SC-005**: Users can find a specific task using filters in under 10 seconds
- **SC-006**: Recurring tasks regenerate within 1 second of the previous instance being completed
- **SC-007**: All task data persists correctly across app restarts

## Assumptions

- The home's member system (from SPEC 02) is already functional and stable
- Category system (from SPEC 04) is available for task categorization
- The app supports Arabic RTL as per project requirements
- Tasks are scoped to a single home; cross-home task views are out of scope
- Task notifications/reminders are deferred to a later phase (SPEC 009 handles general notifications)
- No integration with external calendar apps in this phase
- Offline support follows the existing offline queue pattern — changes are queued and synced when connectivity returns
- Task priority levels (high/medium/low) are deferred to keep the initial scope focused
- Subtasks and task dependencies are out of scope for this phase
