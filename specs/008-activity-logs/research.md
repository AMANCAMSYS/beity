# Research: Activity Logs

**Date**: 2026-05-13
**Feature**: 008-activity-logs

## Decision 1: Database Triggers vs Application-Layer Logging

**Decision**: Use PostgreSQL triggers to generate activity log entries server-side.

**Rationale**:
- Ensures 100% capture rate regardless of which code path performs the action (FR-006)
- Eliminates risk of missing logs due to application bugs or bypassed use cases
- Works for direct database changes (e.g., admin scripts, data fixes)
- Trigger executes within the same transaction — atomic with the action itself

**Alternatives considered**:
- Application-layer logging in use cases: Risk of missing logs if action bypasses use case (e.g., direct Supabase client calls)
- Supabase Edge Functions + Webhooks: Adds latency and complexity; triggers are simpler and more reliable
- CDC (Change Data Capture) with logical replication: Over-engineered for this scale; triggers are sufficient

## Decision 2: Actor Name Denormalization Strategy

**Decision**: Add `actor_name` column to `activity_logs` table. Populate via trigger by joining `users` table at insert time.

**Rationale**:
- Spec requires preserving display name at time of action (FR-009)
- Avoids N+1 queries when rendering the feed (no need to join users table on every read)
- User name changes don't affect historical log entries

**Alternatives considered**:
- Join `users` table on read: Performance cost for feed rendering, name changes affect historical display
- Store full user snapshot in metadata JSON: Over-engineered, actor_name is sufficient
- Client-side caching of user names: Adds complexity, doesn't guarantee historical accuracy

## Decision 3: Real-Time Subscription Approach

**Decision**: Use existing `RealtimeService.watchTable()` (from SPEC 07) to subscribe to `activity_logs` filtered by `home_id`.

**Rationale**:
- Supabase Realtime Postgres Changes already works for this table
- RLS policies already enforce home_id isolation
- No additional infrastructure needed
- Consistent with how other features (shopping lists, items) subscribe to changes

**Alternatives considered**:
- Supabase Realtime Broadcast: Would require custom channel management; Postgres Changes is simpler
- Polling: Doesn't meet <3s propagation requirement
- Firebase FCM for log notifications: Different purpose (push vs. in-app feed)

## Decision 4: Pagination Strategy

**Decision**: Cursor-based pagination using `created_at` timestamp. Load 50 entries initially, fetch more on scroll (infinite scroll).

**Rationale**:
- Spec requires infinite scroll with 500 entry soft limit (FR-013)
- Cursor-based is more efficient than offset-based for append-only data
- `created_at` is already indexed (default timestamp column)
- Supabase `.range()` supports this pattern natively

**Alternatives considered**:
- Offset/limit pagination: Inefficient for large datasets, duplicate entries on insert
- Keyset pagination with UUID: Less intuitive ordering than timestamp
- Load all 500 at once: Too much data transfer for initial load

## Decision 5: Trigger Implementation for Action Types

**Decision**: One trigger function per source table (`shopping_lists`, `shopping_items`, `home_members`, `invitations`), each mapping table events to specific `action` values.

**Rationale**:
- Each table has different columns and semantics for determining the action type
- Separate functions are easier to maintain and debug than a single complex function
- Trigger functions can be tested independently

**Action mapping**:

| Table | Event | action value |
|-------|-------|-------------|
| shopping_lists | INSERT | `list_created` |
| shopping_lists | UPDATE (title changed) | `list_renamed` |
| shopping_lists | UPDATE (status → archived) | `list_archived` |
| shopping_lists | UPDATE (deleted_at set) | `list_deleted` |
| shopping_items | INSERT | `item_added` |
| shopping_items | UPDATE (name/quantity/unit changed, not status) | `item_updated` |
| shopping_items | UPDATE (status → completed) | `item_purchased` |
| shopping_items | UPDATE (status → pending from completed) | `item_unpurchased` |
| shopping_items | UPDATE (deleted_at set) | `item_deleted` |
| home_members | INSERT (status=active) | `member_joined` |
| home_members | UPDATE (deleted_at set) | `member_removed` |
| home_members | UPDATE (role changed) | `member_role_changed` |
| invitations | UPDATE (status → accepted) | `invitation_accepted` |

**Alternatives considered**:
- Single generic trigger function: Too complex, hard to maintain
- Application-layer action mapping: Doesn't meet server-side generation requirement
- Supabase Edge Functions for each event: Adds latency and deployment complexity

## Decision 6: List-Level Activity View Implementation

**Decision**: Query `activity_logs` filtered by `entity_type = 'shopping_list' AND entity_id = <list_id>` OR entries whose `metadata->>'list_id'` matches.

**Rationale**:
- List-level view needs to show both list-level actions (rename, archive) and item-level actions (add, purchase) for that list
- Item-level logs store `list_id` in the `metadata` JSONB field
- List-level logs use `entity_id` directly
- Single query with OR condition covers both cases

**Alternatives considered**:
- Separate `list_id` column on activity_logs: Denormalizes the schema unnecessarily
- Client-side filtering: Inefficient for large log sets
- Two separate queries: Unnecessary complexity
