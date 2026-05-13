# Quickstart: Tasks Phase

**Feature**: 015-tasks-phase
**Date**: 2026-05-13

## Overview

This guide helps developers quickly understand and start working on the Tasks feature.

## Prerequisites

- Beity project set up with Flutter and Supabase
- Familiarity with feature-first clean architecture
- Understanding of existing features (SPEC 01-04)

## Key Concepts

### 1. Task Model

A task represents a household chore with:
- **Title**: Required, max 200 characters
- **Description**: Optional, max 2000 characters
- **Due Date**: Optional, with visual indicators for overdue/due-today
- **Status**: `incomplete` or `completed`
- **Recurrence**: `daily`, `weekly`, `monthly`, or null (non-recurring)
- **Assignment**: Assigned to a home member or unassigned

### 2. Edit Permissions

Only the following users can edit a task:
- **Creator**: The user who created the task
- **Assignee**: The user the task is assigned to
- **Home Admin**: Users with `owner` or `admin` role in the home

Other members can view and comment but cannot edit.

### 3. Task Lifecycle

```
Active (incomplete) → Active (completed, < 7 days) → Archived (completed, >= 7 days)
Active → Deleted (manual soft-delete)
```

- **Active incomplete**: Visible in task list, can be edited/assigned/completed
- **Active completed**: Visible at bottom of task list for 7 days
- **Archived**: Not visible in active list, accessible via "Archived" view
- **Deleted**: Not visible in any view, preserved for audit

### 4. Recurrence

When a recurring task is completed:
- A new task is created with the same title, description, category, assignee, and recurrence
- Due date is calculated: daily (+1 day), weekly (+7 days), monthly (same calendar day next month)
- If original has no due date, new due date = completion date + interval

### 5. Tab Structure

The task list has two tabs:
- **My Tasks**: Tasks assigned to the current user (default tab)
- **All Tasks**: All home tasks

Both tabs share the same filter/sort controls.

## Implementation Steps

### Step 1: Database Migration

Run the SQL contract from `contracts/database.sql`:
- Creates `tasks` and `task_comments` tables
- Sets up RLS policies for home membership isolation
- Creates `archive_old_completed_tasks()`, `create_next_recurring_task()`, and `can_edit_task()` RPC functions
- Sets up triggers for `updated_at` and completion handling

### Step 2: Domain Layer

Create entities and repository interfaces:
```dart
// lib/features/tasks/domain/entities/task.dart
class Task {
  final String id;
  final String homeId;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final String? categoryId;
  final String? assignedTo;
  final String status; // 'incomplete' or 'completed'
  final String? recurrenceType; // 'daily', 'weekly', 'monthly'
  final String? completedBy;
  final DateTime? completedAt;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  // ...
}
```

### Step 3: Data Layer

Implement repositories with Supabase datasource:
- Use `supabase.from('tasks')` for CRUD
- Use `supabase.rpc('create_next_recurring_task')` for recurrence
- Use `supabase.rpc('can_edit_task')` for permission checks
- Handle realtime subscriptions for live updates

### Step 4: Presentation Layer

Build screens with Riverpod providers:
- `TaskListScreen`: Two tabs (My Tasks, All Tasks) with filter bar
- `AddTaskScreen`: Form with recurrence selector and assignee picker
- `TaskDetailScreen`: View/edit task with comment thread
- `ArchivedTasksScreen`: View completed tasks older than 7 days

## Testing Checklist

- [ ] Create task with title only
- [ ] Create task with all optional fields
- [ ] Assign task to member
- [ ] Complete task and verify timestamp/who completed
- [ ] Uncomplete task and verify reset
- [ ] Edit task as creator
- [ ] Edit task as assignee
- [ ] Edit task as home admin
- [ ] Verify non-creator/assignee/admin cannot edit
- [ ] Create recurring task and verify new instance on completion
- [ ] Verify 7-day auto-archive
- [ ] Add comment to task
- [ ] Verify RTL layout works correctly
- [ ] Verify realtime updates for other members
- [ ] Verify "My Tasks" tab shows only assigned tasks
- [ ] Verify "All Tasks" tab shows all home tasks

## Common Pitfalls

1. **Edit permissions**: Check creator, assignee, AND admin role — not just one
2. **Recurrence**: New task inherits all properties from completed task
3. **Auto-archive**: Runs via pg_cron, not in the app — query with `WHERE archived_at IS NULL`
4. **Soft delete**: Always filter `WHERE deleted_at IS NULL` in queries
5. **RLS**: All queries must go through Supabase client (not raw SQL)
6. **Realtime**: Subscribe on screen mount, unsubscribe on dispose
7. **Concurrent completion**: First write wins, second rejected with error

## References

- [Spec](./spec.md) — Feature requirements
- [Data Model](./data-model.md) — Entity definitions
- [Database Contract](./contracts/database.sql) — SQL schema
- [Research](./research.md) — Design decisions
