# Research: Tasks Phase

**Feature**: 015-tasks-phase
**Date**: 2026-05-13

## Research Tasks

### 1. Task Edit Permission Model

**Decision**: Creator, assignee, and home admin can edit tasks.

**Rationale**:
- Creator: owns the task definition and should retain control
- Assignee: needs to modify task details as they work on it
- Home admin: needs oversight capability for household management
- Other members can view and comment but not edit (prevents accidental changes)

**Alternatives Considered**:
- Any member can edit: Too permissive, risks accidental changes to others' tasks
- Creator-only: Too restrictive, assignee can't update details as work progresses
- Creator + assignee only: Missing admin oversight for household coordination

**Implementation Notes**:
- Check role via `home_members` table: `role IN ('owner', 'admin')`
- Check creator: `created_by = auth.uid()`
- Check assignee: `assigned_to = auth.uid()`
- RLS policy: `USING (created_by = auth.uid() OR assigned_to = auth.uid() OR home_id IN (SELECT home_id FROM home_members WHERE user_id = auth.uid() AND role IN ('owner', 'admin')))`

---

### 2. Recurrence Pattern Implementation

**Decision**: Support daily, weekly, and monthly recurrence with simple interval-based calculation.

**Rationale**:
- Daily: +1 day from completion date
- Weekly: +7 days from completion date
- Monthly: Same calendar day next month (fallback to last day if invalid, e.g., Jan 31 → Feb 28)
- No day-of-week selection needed — simplifies data model and UI significantly

**Alternatives Considered**:
- Bi-weekly: Adds complexity, can be achieved by completing weekly tasks every other time
- Custom day-of-week: Overcomplicates UI for household use case
- Cron-like expressions: Way too complex for home users

**Implementation Notes**:
- Store `recurrence_type` enum: `daily`, `weekly`, `monthly` (nullable for non-recurring)
- On completion of recurring task: create new task with calculated due_date
- If no due_date on original: use completion_date + interval
- Edge case: monthly recurrence on 31st → use last day of shorter months
- New task inherits all properties (title, description, category, assignee, recurrence)

---

### 3. Auto-Archive Completed Tasks

**Decision**: Completed tasks are automatically archived after 7 days via a database function.

**Rationale**:
- Keeps active task list clean and focused on actionable items
- 7-day window allows review of recently completed work
- Archived tasks remain accessible for history
- Consistent with soft-delete pattern used elsewhere in the project

**Alternatives Considered**:
- No auto-archive: List grows indefinitely, poor UX
- 30 days: Too long, defeats the purpose of archiving
- Manual archive only: Users won't do it, list gets cluttered

**Implementation Notes**:
- Add `archived_at` timestamp column to tasks table (nullable)
- Background job (Supabase pg_cron) runs daily: `UPDATE tasks SET archived_at = now() WHERE status = 'completed' AND completed_at < now() - interval '7 days' AND archived_at IS NULL`
- Query filter: `WHERE archived_at IS NULL` for active views
- Separate "Archived" view: `WHERE archived_at IS NOT NULL`
- Can also manually archive via soft-delete button

---

### 4. Task List Tab Structure

**Decision**: Two tabs — "My Tasks" and "All Tasks" with shared filter bar.

**Rationale**:
- "My Tasks": Default tab, shows tasks assigned to current user (most common use case)
- "All Tasks": Shows all home tasks for coordination and overview
- Both tabs share the same filter/sort controls
- Reduces taps for the primary workflow (checking what I need to do)

**Alternatives Considered**:
- Single list with filters: Requires extra taps every time for the common case
- Three tabs (My Tasks, Assigned to Me, All Tasks): Redundant — "My Tasks" already means "assigned to me"

**Implementation Notes**:
- Tab 1 query: `WHERE assigned_to = auth.uid() AND archived_at IS NULL`
- Tab 2 query: `WHERE archived_at IS NULL` (all active tasks)
- Default sort: incomplete first, then by due_date ascending (nulls last)
- Completed tasks (within 7 days) shown at bottom of each tab

---

### 5. RLS Policies for Task Tables

**Decision**: Implement RLS policies ensuring home membership is verified for all operations.

**Rationale**:
- Aligns with constitution principle: "Users can only access data where they are active members"
- Prevents cross-home data leakage
- Consistent with existing RLS patterns in shopping list and expenses features

**Alternatives Considered**:
- Application-level auth only: Violates RLS-first principle
- API-level checks: Insufficient, database must enforce

**Implementation Notes**:
- Tasks table: `home_id` column with RLS check via `home_members`
- Task comments table: RLS via parent task's `home_id`
- SELECT: Home members only
- INSERT: Home members only
- UPDATE: Creator, assignee, or admin (edit permissions)
- DELETE: Soft delete only (set `deleted_at`)

---

### 6. Soft Delete for Tasks

**Decision**: Use `deleted_at` timestamp column for soft deletion, separate from `archived_at`.

**Rationale**:
- `deleted_at`: Manual soft-delete by user (removes from all views)
- `archived_at`: Automatic archive after 7 days (removes from active, visible in archived)
- A task can be both archived and deleted
- Preserves audit trail as required by constitution

**Alternatives Considered**:
- Single status field: Less flexible, can't distinguish between archive and delete
- Hard delete: Loses audit trail, breaks comment references

**Implementation Notes**:
- Active tasks: `deleted_at IS NULL AND archived_at IS NULL`
- Archived tasks: `deleted_at IS NULL AND archived_at IS NOT NULL`
- Deleted tasks: `deleted_at IS NOT NULL`
- Query for active views: `WHERE deleted_at IS NULL AND archived_at IS NULL`

---

### 7. Realtime Sync for Tasks

**Decision**: Use Supabase Realtime subscriptions on `tasks` and `task_comments` tables.

**Rationale**:
- Leverages existing Supabase Realtime infrastructure from shopping list and expenses features
- Changes broadcast to all home members automatically
- Consistent with project's realtime collaboration principle

**Alternatives Considered**:
- Polling: Wastes bandwidth, slower updates
- Firebase Realtime: Inconsistent with Supabase-first architecture

**Implementation Notes**:
- Subscribe to `tasks` table filtered by `home_id`
- Subscribe to `task_comments` table filtered by `home_id`
- Handle INSERT, UPDATE, DELETE events
- Unsubscribe on screen dispose
- Handle concurrent completion: first write wins, second rejected with error message

---

## Technology Decisions Summary

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Edit permissions | Creator + assignee + admin | Balances ownership with oversight |
| Recurrence | Daily, weekly, monthly (simple) | Covers 95% of household chore patterns |
| Auto-archive | 7 days after completion | Keeps list clean, allows review window |
| Tab structure | "My Tasks" + "All Tasks" | Reduces taps for primary workflow |
| RLS | Home membership check | Constitution requirement |
| Soft delete | `deleted_at` + `archived_at` | Distinguishes manual delete from auto-archive |
| Realtime | Supabase Realtime | Consistent with existing architecture |
