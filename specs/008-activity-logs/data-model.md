# Data Model: Activity Logs

**Date**: 2026-05-13
**Feature**: 008-activity-logs

## Existing Table (Schema Already Exists)

### activity_logs

The `activity_logs` table already exists in Supabase. Schema verification:

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | NO | uuid_generate_v4() | Primary key |
| home_id | uuid | NO | — | FK → homes.id |
| user_id | uuid | NO | — | FK → users.id (the actor) |
| action | text | NO | — | Action type (see enum below) |
| entity_type | text | NO | — | Target entity type |
| entity_id | uuid | YES | — | Target entity ID |
| entity_name | text | YES | — | Target entity name at time of action |
| metadata | jsonb | YES | — | Additional context (before/after values, list_id for items) |
| created_at | timestamptz | YES | now() | When the action occurred |

### Existing RLS Policies

| Policy | Command | Rule |
|--------|---------|------|
| Users can view activity from their homes | SELECT | home_id IN (active home_members for auth.uid()) |
| Authenticated users can insert activity logs | INSERT | user_id = auth.uid() AND home_id IN (active home_members) |

## Schema Changes Required

### Migration: Add actor_name column

```sql
ALTER TABLE activity_logs ADD COLUMN actor_name text;
```

- **Purpose**: Denormalize actor's display name for historical accuracy (FR-009)
- **Populated by**: Trigger function joining `users` table at insert time
- **Nullable**: YES (existing rows won't have this; backfill not required for MVP)

### Migration: Add index for list-level queries

```sql
CREATE INDEX idx_activity_logs_entity ON activity_logs (entity_type, entity_id, created_at DESC);
CREATE INDEX idx_activity_logs_home_created ON activity_logs (home_id, created_at DESC);
```

- **Purpose**: Efficient filtering for home feed and list-level views
- **Impact**: Improves query performance for the two primary access patterns

## Action Type Enum

Stored as `text` in the `action` column. Valid values:

| Value | Source Table | Trigger Event | Description |
|-------|-------------|---------------|-------------|
| `list_created` | shopping_lists | INSERT | New shopping list created |
| `list_renamed` | shopping_lists | UPDATE (title changed) | Shopping list renamed |
| `list_archived` | shopping_lists | UPDATE (status → archived) | Shopping list archived |
| `list_deleted` | shopping_lists | UPDATE (deleted_at set) | Shopping list soft-deleted |
| `item_added` | shopping_items | INSERT | New item added to list |
| `item_updated` | shopping_items | UPDATE (non-status fields) | Item details edited |
| `item_purchased` | shopping_items | UPDATE (status → completed) | Item marked as purchased |
| `item_unpurchased` | shopping_items | UPDATE (status → pending) | Item unmarked |
| `item_deleted` | shopping_items | UPDATE (deleted_at set) | Item soft-deleted |
| `member_joined` | home_members | INSERT (status=active) | New member joined home |
| `member_removed` | home_members | UPDATE (deleted_at set) | Member removed from home |
| `member_role_changed` | home_members | UPDATE (role changed) | Member role changed |
| `invitation_accepted` | invitations | UPDATE (status → accepted) | Invitation accepted |

## Entity Type Enum

Stored as `text` in the `entity_type` column:

| Value | Description |
|-------|-------------|
| `shopping_list` | Shopping list entity |
| `shopping_item` | Shopping item entity |
| `home_member` | Home membership entity |
| `invitation` | Invitation entity |

## Metadata Schema (JSONB)

The `metadata` column stores additional context. Structure varies by action type:

### List actions
```json
{
  "old_name": "Weekly Groceries",  // for list_renamed
  "new_name": "Weekly Shopping"    // for list_renamed
}
```

### Item actions
```json
{
  "list_id": "uuid",           // parent list ID (for list-level filtering)
  "list_name": "Groceries",    // parent list name (for display)
  "old_values": { ... },       // for item_updated (changed fields)
  "new_values": { ... }        // for item_updated (changed fields)
}
```

### Member actions
```json
{
  "old_role": "member",        // for member_role_changed
  "new_role": "admin",         // for member_role_changed
  "member_name": "Omar"        // for member_removed, member_role_changed
}
```

## Trigger Functions

### log_shopping_list_activity()

Fires on `shopping_lists` AFTER INSERT OR UPDATE.

- INSERT → `list_created`, entity_name = title
- UPDATE where title changed → `list_renamed`, metadata = {old_name, new_name}
- UPDATE where status → 'archived' → `list_archived`, entity_name = title
- UPDATE where deleted_at IS NOT NULL → `list_deleted`, entity_name = title

### log_shopping_item_activity()

Fires on `shopping_items` AFTER INSERT OR UPDATE.

- INSERT → `item_added`, entity_name = name, metadata includes list_id + list_name
- UPDATE where non-status fields changed AND deleted_at IS NULL → `item_updated`, metadata includes old/new values
- UPDATE where status → 'completed' → `item_purchased`, entity_name = name
- UPDATE where status → 'pending' (was completed) → `item_unpurchased`, entity_name = name
- UPDATE where deleted_at IS NOT NULL → `item_deleted`, entity_name = name

### log_home_member_activity()

Fires on `home_members` AFTER INSERT OR UPDATE.

- INSERT where status = 'active' → `member_joined`, entity_name = user's full_name
- UPDATE where deleted_at IS NOT NULL → `member_removed`, entity_name = user's full_name
- UPDATE where role changed → `member_role_changed`, metadata = {old_role, new_role}

### log_invitation_activity()

Fires on `invitations` AFTER UPDATE.

- UPDATE where status → 'accepted' → `invitation_accepted`, entity_name = email/phone

All trigger functions:
1. Look up `actor_name` from `users.full_name` WHERE id = NEW.user_id (or relevant user column)
2. Set `home_id` from the source record's home_id
3. Set `user_id` to `auth.uid()` (the authenticated user performing the action)
4. Populate `entity_type`, `entity_id`, `entity_name`, `metadata` based on action

## Realtime Channel

| Scope | Channel Name | Content |
|-------|-------------|---------|
| Home activity feed | `realtime:public:activity_logs:home_id=<uuid>` | Postgres Changes (INSERT) |

RLS ensures users only receive changes for homes they belong to.

## Domain Entity (Dart)

```dart
enum ActionType {
  listCreated, listRenamed, listArchived, listDeleted,
  itemAdded, itemUpdated, itemPurchased, itemUnpurchased, itemDeleted,
  memberJoined, memberRemoved, memberRoleChanged,
  invitationAccepted,
}

enum EntityType { shoppingList, shoppingItem, homeMember, invitation }

class ActivityLog {
  final String id;
  final String homeId;
  final String userId;
  final String? actorName;
  final ActionType action;
  final EntityType entityType;
  final String? entityId;
  final String? entityName;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
}
```
