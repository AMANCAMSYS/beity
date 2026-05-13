# Data Model: Shopping Mode

**Feature**: 010-shopping-mode  
**Date**: 2026-05-13

## New Entity: Shopping Mode Session

Represents a shopping session where a user actively shops from a shopping list.

### Table: `shopping_mode_sessions`

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| id | UUID | NO | gen_random_uuid() | Primary key |
| shopping_list_id | UUID | NO | — | FK to shopping_lists.id |
| user_id | UUID | NO | auth.uid() | FK to auth.users.id, the shopper |
| home_id | UUID | NO | — | FK to homes.id, for RLS isolation |
| started_at | TIMESTAMPTZ | NO | NOW() | When shopping mode was entered |
| ended_at | TIMESTAMPTZ | YES | — | When shopping mode was exited |
| items_purchased_count | INT | NO | 0 | Number of items marked purchased during session |
| items_total_count | INT | NO | 0 | Total items in list when session started |
| created_at | TIMESTAMPTZ | NO | NOW() | Row creation time |
| updated_at | TIMESTAMPTZ | NO | NOW() | Last update time |

### Constraints

- **Primary Key**: `id`
- **Foreign Keys**: 
  - `shopping_list_id` → `shopping_lists(id)` ON DELETE CASCADE
  - `user_id` → `auth.users(id)` ON DELETE CASCADE
  - `home_id` → `homes(id)` ON DELETE CASCADE
- **Unique**: None (multiple sessions per list allowed for history)

### Indexes

| Name | Columns | Purpose |
|------|---------|---------|
| idx_shopping_mode_sessions_list | shopping_list_id, started_at DESC | Get sessions for a list |
| idx_shopping_mode_sessions_user | user_id, started_at DESC | Get user's shopping history |
| idx_shopping_mode_sessions_active | user_id, ended_at | Find active session (where ended_at IS NULL) |
| idx_shopping_mode_sessions_home | home_id, started_at DESC | Home-level session queries |

### RLS Policies

| Policy | Operation | USING | WITH CHECK |
|--------|-----------|-------|------------|
| Users can view sessions in their home | SELECT | home_id IN (SELECT home_id FROM home_members WHERE user_id = auth.uid()) | — |
| Users can create sessions in their home | INSERT | — | home_id IN (SELECT home_id FROM home_members WHERE user_id = auth.uid()) AND user_id = auth.uid() |
| Users can update own sessions | UPDATE | user_id = auth.uid() | user_id = auth.uid() |

### State Transitions

```
[Created] → started_at set, ended_at NULL
    ↓
[Active] → items_purchased_count updates as items are marked
    ↓
[Ended] → ended_at set, final counts recorded
```

### Relationship to Existing Entities

```
homes (1) ──< shopping_lists (1) ──< shopping_mode_sessions (N)
                          │
                          └──< shopping_items (N)
```

- A shopping list can have multiple sessions over time
- A session tracks activity on a single list
- Shopping items are the existing items being shopped (no schema change needed)
- `home_id` is denormalized for RLS performance (avoids join through shopping_lists)

## Existing Entities (No Changes)

### Shopping Item (from SPEC 006)

No schema changes. Shopping mode reads/writes the same `shopping_items` table.

Key fields used in shopping mode:
- `id`, `shopping_list_id`, `name`, `quantity`, `unit`
- `category_id` (for grouping)
- `is_purchased`, `purchased_by`, `purchased_at`
- `created_by`, `created_at`, `updated_at`

### Shopping List (from SPEC 005)

No schema changes. Shopping mode operates on an existing list.

Key fields used in shopping mode:
- `id`, `home_id`, `name`

### Item Template (from SPEC 006)

No schema changes. Used for autocomplete suggestions in quick-add.

## Migration SQL

```sql
-- Shopping Mode Sessions Migration
-- Creates shopping_mode_sessions table with RLS policies

-- ============================================================
-- 1. shopping_mode_sessions table
-- ============================================================

CREATE TABLE IF NOT EXISTS shopping_mode_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shopping_list_id UUID NOT NULL REFERENCES shopping_lists(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  home_id UUID NOT NULL REFERENCES homes(id) ON DELETE CASCADE,
  started_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  ended_at TIMESTAMP WITH TIME ZONE,
  items_purchased_count INT NOT NULL DEFAULT 0,
  items_total_count INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_shopping_mode_sessions_list ON shopping_mode_sessions(shopping_list_id, started_at DESC);
CREATE INDEX IF NOT EXISTS idx_shopping_mode_sessions_user ON shopping_mode_sessions(user_id, started_at DESC);
CREATE INDEX IF NOT EXISTS idx_shopping_mode_sessions_active ON shopping_mode_sessions(user_id, ended_at) WHERE ended_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_shopping_mode_sessions_home ON shopping_mode_sessions(home_id, started_at DESC);

-- RLS
ALTER TABLE shopping_mode_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view sessions in their home"
ON shopping_mode_sessions FOR SELECT
USING (home_id IN (SELECT home_id FROM home_members WHERE user_id = auth.uid()));

CREATE POLICY "Users can create sessions in their home"
ON shopping_mode_sessions FOR INSERT
WITH CHECK (
  home_id IN (SELECT home_id FROM home_members WHERE user_id = auth.uid())
  AND user_id = auth.uid()
);

CREATE POLICY "Users can update own sessions"
ON shopping_mode_sessions FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Trigger for updated_at
CREATE TRIGGER set_shopping_mode_sessions_updated_at
BEFORE UPDATE ON shopping_mode_sessions
FOR EACH ROW
EXECUTE FUNCTION moddatetime(updated_at);
```
