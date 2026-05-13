# Research: Realtime Sync

**Date**: 2026-05-13
**Feature**: 007-realtime-sync

## Decision 1: Supabase Realtime Postgres Changes vs Custom Webhooks

**Decision**: Use Supabase's built-in `.stream(primaryKey:)` (Postgres Changes) for data sync. Already in use.

**Rationale**: The project already uses `.stream()` on shopping_lists, shopping_items, categories, and invitations. This is the Supabase-recommended approach for Flutter. No custom webhooks or edge functions needed for data sync.

**Alternatives considered**:
- Custom Supabase Edge Functions + WebSockets: More control but unnecessary complexity for this scale
- Firebase Realtime Database: Would require duplicating Supabase data in Firebase
- Polling: Too slow for <1s requirement, wastes bandwidth

## Decision 2: Presence Implementation

**Decision**: Use Supabase Realtime Presence (built into supabase_flutter SDK) via `channel.onPresenceSync()`.

**Rationale**: Supabase Presence is:
- Built into the same Realtime connection as Postgres Changes (no extra connections)
- Ephemeral (no database storage needed)
- Handles join/leave lifecycle automatically
- Supports broadcasting user metadata (user_id, name, avatar_url)

Channel naming convention: `presence:list:<list_id>` — scopes presence to specific shopping list.

**Alternatives considered**:
- Custom `online_users` table with heartbeat: Persistent but requires cleanup logic, more DB writes
- Firebase Presence: Requires Firebase Realtime Database, conflicts with Supabase-first architecture

## Decision 3: Connection State Detection

**Decision**: Use `connectivity_plus` package for network state + Supabase Realtime `CHANNEL_ERROR` / `CHANNEL_OPEN` events for server connectivity.

**Rationale**: 
- `connectivity_plus` detects network interface changes (WiFi/mobile/offline)
- Supabase channel events detect actual server connectivity (network may be up but Supabase down)
- Combined approach covers both scenarios

**Alternatives considered**:
- HTTP polling health check: Wastes battery and bandwidth
- Relying only on Supabase channel events: Misses network-down detection before channel attempt

## Decision 4: Offline Queue Storage

**Decision**: In-memory queue (Dart list) within Riverpod state. Discarded on app restart or logout.

**Rationale**: 
- Spec clarification: discard on logout with warning
- No persistent storage needed (Isar deferred to post-MVP)
- Simpler implementation, no migration path needed later
- Family groups (2-10 members) unlikely to have large offline queues

**Alternatives considered**:
- Shared Preferences: Would serialize operations, but spec says discard on logout anyway
- SQLite/Isar: Over-engineered for session-only queue, deferred per constitution

## Decision 5: Conflict Resolution UX

**Decision**: Server is source of truth (last-write-wins via `updated_at`). Client detects conflicts by comparing local optimistic update timestamp with incoming realtime update. Shows toast + highlight.

**Rationale**:
- Supabase Postgres already uses `updated_at` column
- Client can detect when an incoming realtime update overwrites a recent local change
- Toast + 3s highlight (per spec clarification) provides clear feedback without blocking UX

**Alternatives considered**:
- CRDT-based merging: Far too complex for MVP, requires custom merge logic
- Operational Transform: Same complexity issue
- No feedback (silent overwrite): Spec explicitly requires notification

## Decision 6: Removed Member Detection

**Decision**: Subscribe to `home_members` stream filtered by current user's ID. When a DELETE or `deleted_at` update is received, trigger redirect.

**Rationale**:
- Supabase Postgres Changes captures DELETE and UPDATE events
- The existing `watchHomeMembers` stream already exists in `supabase_role_repository.dart`
- Can be enhanced to detect removal by watching for the current user's membership disappearing

**Alternatives considered**:
- Polling `home_members` on interval: Slow detection, wastes resources
- Server push notification: Requires FCM setup, deferred per spec
