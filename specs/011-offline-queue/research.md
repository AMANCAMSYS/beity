# Research: Offline Queue

**Feature**: Offline Queue (SPEC 011)  
**Date**: 2026-05-13  
**Status**: Complete

## Research Questions

### 1. Local Storage Solution for Queue

**Question**: What local storage mechanism should be used for persisting the offline queue?

**Decision**: Isar

**Rationale**: 
- Already listed as a dependency in AGENTS.md for offline support
- High-performance NoSQL database optimized for Flutter
- Supports complex queries for queue management (filter by status, order by timestamp)
- Transactional writes ensure queue consistency
- Well-maintained with good Flutter integration

**Alternatives Considered**:
- **SQLite (sqflite)**: More mature but requires manual schema management and SQL queries. Isar provides a more Flutter-native API.
- **Hive**: Simpler but lacks query capabilities needed for queue management (filtering by status, ordering).
- **SharedPreferences**: Only suitable for simple key-value data, not complex queue structures.

---

### 2. Connectivity Detection Strategy

**Question**: How should the app detect online/offline status?

**Decision**: Hybrid approach using connectivity_plus package + Supabase server reachability check

**Rationale**:
- `connectivity_plus` provides network connectivity status (WiFi/cellular)
- Network connectivity alone is insufficient (device may have WiFi but no internet)
- Adding a lightweight Supabase health check confirms actual server reachability
- Supabase Realtime subscription state can serve as an additional signal

**Alternatives Considered**:
- **Network connectivity only**: Simpler but produces false positives (connected to WiFi but no internet).
- **Server ping only**: More accurate but requires periodic polling, consuming battery.
- **Realtime subscription state**: Good signal but not sufficient alone (subscription may drop for reasons other than connectivity loss).

---

### 3. Retry Strategy Implementation

**Question**: How should exponential backoff with max 5 retries be implemented?

**Decision**: Custom implementation using Dart's Timer with exponential delays

**Rationale**:
- No need for external packages for this simple pattern
- Delays: 1s, 2s, 4s, 8s, 16s (total max wait: 31s)
- Each retry is independent per queue entry
- Failed entries after max retries are marked as permanently failed
- User can manually retry failed entries (resets retry counter)

**Alternatives Considered**:
- **retry package**: Adds dependency for a simple pattern we can implement in ~20 lines.
- **Riverpod retry logic**: Could work but mixing retry logic with state management adds complexity.

---

### 4. Conflict Resolution Implementation

**Question**: How should last-write-wins conflict resolution be implemented?

**Decision**: Compare `updated_at` timestamps between local queued action and server state

**Rationale**:
- Each queue entry stores the timestamp when the action was performed locally
- During sync, fetch current server state for the entity
- Compare local action timestamp with server `updated_at`
- If local is newer, apply the change; if server is newer, discard local change and notify user
- Uses existing `updated_at` fields on shopping_items table

**Alternatives Considered**:
- **Server-wins always**: Simpler but loses user's offline work.
- **Client-wins always**: Simpler but may overwrite newer server changes.
- **Merge-by-field**: More complex to implement and test; overkill for shopping list scenarios.

---

### 5. Queue Entry State Machine

**Question**: What are the valid states and transitions for queue entries?

**Decision**: Linear flow with retry capability

**States**:
- `pending`: Initial state, waiting to sync
- `syncing`: Currently being synced to server
- `completed`: Successfully synced (entry removed immediately)
- `failed`: Sync failed after max retries

**Transitions**:
- `pending` → `syncing`: When sync attempt starts
- `syncing` → `completed`: When sync succeeds (entry deleted)
- `syncing` → `failed`: When max retries exhausted
- `failed` → `syncing`: When user manually retries

**Rationale**:
- Simple state machine covers all scenarios
- Completed entries are cleaned up immediately to minimize storage
- Failed entries remain for user visibility and manual retry
- No "cancelled" state needed (user can delete the original entity instead)

---

### 6. Integration with Existing Shopping Features

**Question**: How should the offline queue integrate with existing shopping_lists and shopping_items features?

**Decision**: Decorator/wrapper pattern — offline queue wraps existing repository calls

**Rationale**:
- When online: calls go directly to existing Supabase repositories
- When offline: actions are queued locally and UI is updated optimistically
- During sync: queued actions are replayed against existing repositories
- Minimal changes to existing feature code
- Queue feature acts as a middleware layer

**Alternatives Considered**:
- **Modify existing repositories directly**: Higher coupling, harder to test, violates open-closed principle.
- **Event sourcing pattern**: Over-engineered for this use case; adds significant complexity.

---

### 7. Optimistic UI Updates

**Question**: How should the UI reflect changes before they're synced?

**Decision**: Apply changes to local state immediately, show pending indicator

**Rationale**:
- User sees their action reflected instantly (< 1s as per SC-001)
- Pending sync indicator (icon/color) shows the item hasn't been synced yet
- If sync fails, item shows failed indicator with retry option
- Consistent with modern offline-first app patterns

**Alternatives Considered**:
- **Wait for sync confirmation**: Poor UX — user thinks action didn't work.
- **Show loading spinner**: Distracting and blocks interaction.
