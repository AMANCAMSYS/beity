# Data Model: Realtime Sync

**Date**: 2026-05-13
**Feature**: 007-realtime-sync

## New Entities (Client-Side Only)

These are ephemeral client-side structures. No new database tables required.

### RealtimeChannel

Represents a Supabase Realtime channel subscription.

| Field | Type | Description |
|-------|------|-------------|
| name | String | Channel name (e.g., `realtime:public:shopping_items:list_id=<uuid>`) |
| status | ChannelStatus | `subscribed`, `subscribing`, `closed`, `error` |
| subscribedAt | DateTime? | When subscription was established |

**Lifecycle**: `idle → subscribing → subscribed → closed`
**Errors**: `subscribing → error` (retry with backoff)

### PresenceState

Represents users currently viewing a specific shopping list.

| Field | Type | Description |
|-------|------|-------------|
| userId | String | User UUID |
| displayName | String | User's full_name |
| avatarUrl | String? | User's avatar URL |
| listId | String | Shopping list being viewed |
| joinedAt | DateTime | When presence was established |

**Lifecycle**: Join on list view → Leave on navigate away or app background
**Channel**: `presence:list:<list_id>`

### ConnectionState

Represents device connectivity to Supabase Realtime.

| Field | Type | Description |
|-------|------|-------------|
| status | ConnectionStatus | `connected`, `disconnected`, `reconnecting` |
| lastConnectedAt | DateTime? | Last time connection was established |
| pendingSyncCount | int | Number of changes fetched on reconnect |

**Transitions**: `connected → disconnected` (network loss), `disconnected → reconnecting` (network restored), `reconnecting → connected` (sync complete)

### OfflineQueueEntry

Represents a pending mutation made while offline.

| Field | Type | Description |
|-------|------|-------------|
| id | String | UUID for deduplication |
| operation | QueueOperation | `add`, `update`, `delete`, `markPurchased` |
| entityType | String | `shopping_item`, `shopping_list` |
| entityId | String? | Target entity ID (null for adds) |
| payload | Map<String, dynamic> | Mutation data |
| createdAt | DateTime | When the operation was queued |

**Lifecycle**: Created on offline mutation → Executed on reconnect → Cleared on logout/app restart
**Storage**: In-memory Riverpod state (not persisted)
**Discard**: On logout with user warning (per spec clarification)

## Modified Entities (Existing Database)

### shopping_items

No schema changes. Existing `updated_at` column used for conflict detection.

**Conflict detection**: Client stores last local mutation timestamp. When realtime update arrives with `updated_at > local_mutation_timestamp`, the local change was overwritten → show toast + highlight.

### home_members

No schema changes. Existing stream used for removed member detection.

**Detection**: Subscribe to `home_members` stream filtered by `user_id = current_user_id`. If DELETE event received or `deleted_at` becomes non-null → trigger redirect dialog.

## Channel Naming Convention

| Scope | Channel Name | Content |
|-------|-------------|---------|
| Shopping list items | `realtime:public:shopping_items:list_id=<uuid>` | Postgres Changes (INSERT, UPDATE, DELETE) |
| Shopping lists (home) | `realtime:public:shopping_lists:home_id=<uuid>` | Postgres Changes |
| List presence | `presence:list:<list_id>` | Presence (join/leave) |
| Home members | `realtime:public:home_members:home_id=<uuid>` | Postgres Changes |
| Categories | `realtime:public:categories:home_id=<uuid>` | Postgres Changes |

## RLS Impact

No new RLS policies needed. Existing policies on `shopping_items`, `shopping_lists`, `home_members`, and `categories` already enforce home_id-based isolation. Supabase Realtime respects RLS — users only receive changes for rows they can SELECT.
