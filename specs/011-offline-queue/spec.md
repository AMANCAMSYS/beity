# Feature Specification: Offline Queue

**Feature Branch**: `011-offline-queue`  
**Created**: 2026-05-13  
**Status**: Draft  
**Input**: User description: "# SPEC 11 — Offline Queue"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Queue Actions While Offline (Priority: P1)

As a shopper with unstable or no internet connection, I want my actions (adding items, marking items as purchased, updating quantities) to be saved locally and automatically synced when I regain connectivity, so that I never lose my shopping progress.

**Why this priority**: This is the core value proposition of the offline queue. Without this, users in stores with poor connectivity would lose data or be unable to use the app.

**Independent Test**: Can be fully tested by enabling airplane mode, performing multiple shopping actions, disabling airplane mode, and verifying all actions sync correctly.

**Acceptance Scenarios**:

1. **Given** the user is offline, **When** they add an item to the shopping list, **Then** the item appears locally with a "pending sync" indicator and is queued for synchronization.
2. **Given** the user is offline, **When** they mark an item as purchased, **Then** the item is marked locally with a "pending sync" indicator and the action is queued.
3. **Given** the user is offline, **When** they update an item's quantity, **Then** the change is saved locally with a "pending sync" indicator and queued.
4. **Given** the user has queued actions, **When** connectivity is restored, **Then** all queued actions sync automatically in the correct order without user intervention.

---

### User Story 2 - View Pending Sync Status (Priority: P2)

As a shopper, I want to see which items have pending changes and the overall sync status, so that I understand what will be synchronized when I'm back online.

**Why this priority**: Visibility into sync status builds user confidence and helps troubleshoot issues.

**Independent Test**: Can be tested by going offline, making changes, and verifying visual indicators appear on modified items and in a status area.

**Acceptance Scenarios**:

1. **Given** the user has queued actions, **When** they view the shopping list, **Then** items with pending changes display a visual indicator (e.g., icon or color change).
2. **Given** the user has queued actions, **When** they view the shopping list header or status area, **Then** they see a count or summary of pending actions.
3. **Given** all queued actions have synced, **When** the user views the list, **Then** no pending indicators remain.

---

### User Story 3 - Handle Sync Conflicts (Priority: P3)

As a shopper sharing a list with others, I want the app to gracefully handle conflicts when my offline changes conflict with changes made by others, so that no data is lost and the final state is consistent.

**Why this priority**: Conflict resolution is essential for shared lists but is less common than basic queuing scenarios.

**Independent Test**: Can be tested by having two users modify the same item while one is offline, then verifying the conflict is resolved appropriately when the offline user reconnects.

**Acceptance Scenarios**:

1. **Given** the user marked an item as purchased offline, **When** another user deleted that same item while they were offline, **Then** the system resolves using last-write-wins — if the purchase was timestamped after the deletion, the item is preserved as purchased; if the deletion was later, the item is removed.
2. **Given** the user updated an item's quantity offline, **When** another user also updated the same quantity, **Then** the system applies last-write-wins — the update with the more recent timestamp becomes the final state, and both users see the same result.
3. **Given** a conflict occurred, **When** the sync completes, **Then** the user is notified of any conflicts where their offline changes were overwritten by a more recent server state.

---

### User Story 4 - Manual Retry for Failed Syncs (Priority: P4)

As a shopper, I want to manually retry failed sync actions, so that I can resolve issues without losing my queued changes.

**Why this priority**: Automatic retry handles most cases, but manual retry provides a safety net for persistent failures.

**Independent Test**: Can be tested by simulating a sync failure (e.g., invalid data), verifying the retry option appears, and confirming the action succeeds after the issue is resolved.

**Acceptance Scenarios**:

1. **Given** a queued action failed to sync, **When** the user taps a retry option, **Then** the system re-attempts the sync for that action.
2. **Given** multiple queued actions failed, **When** the user taps "Retry All", **Then** the system re-attempts all failed actions.

---

### Edge Cases

- What happens when the app is killed while there are queued actions? (Queue must persist across app restarts)
- How does the system handle extremely large queues (e.g., 500+ queued actions)?
- What happens when the user switches homes while offline actions are queued?
- How does the system handle actions queued for items that were deleted by another user?
- What happens if the device storage is full and the queue cannot be saved?
- How does the system handle partial sync failures (e.g., 3 of 5 actions sync successfully)? (Failed actions retry independently with exponential backoff up to 5 attempts)
- What happens when a queued action exhausts all 5 retry attempts? (Action is marked as failed and user is notified with option to manually retry)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST queue user actions (add item, update item, delete item, mark purchased, update quantity) locally when the device has no internet connectivity.
- **FR-002**: System MUST persist the offline queue across app restarts and device reboots.
- **FR-003**: System MUST detect offline status using a hybrid approach: network connectivity loss OR server reachability failure triggers offline mode.
- **FR-004**: System MUST automatically attempt to sync queued actions when connectivity is restored.
- **FR-005**: System MUST preserve the chronological order of queued actions during sync.
- **FR-006**: System MUST display visual indicators on items with pending unsynchronized changes.
- **FR-007**: System MUST display a sync status summary showing the count of pending actions.
- **FR-008**: System MUST detect and resolve conflicts between offline changes and server state using last-write-wins strategy (most recent change by timestamp takes precedence).
- **FR-009**: System MUST notify users when conflicts are resolved with non-obvious outcomes.
- **FR-010**: System MUST provide a manual retry option for failed sync actions.
- **FR-011**: System MUST handle partial sync failures by retrying failed actions independently using exponential backoff (1s, 2s, 4s, 8s, 16s) with a maximum of 5 retry attempts before marking the action as failed.
- **FR-012**: System MUST immediately remove queue entries from local storage after successful sync; failed entries remain visible for manual retry.
- **FR-013**: System MUST support Arabic RTL layout for all offline queue UI elements.
- **FR-014**: System MUST queue actions per home, ensuring actions for one home do not affect another.

### Key Entities

- **Offline Queue Entry**: Represents a single queued action waiting to be synced. Contains the action type, entity ID, payload data, timestamp, home context, and sync status. Valid state transitions: pending → syncing → completed; failed → syncing (on retry) → completed or failed. Entries are removed from local storage immediately upon reaching completed state.
- **Sync Status**: The current synchronization state of the device — online with no pending actions, online with pending actions, or offline. Determined by hybrid detection (network connectivity + server reachability).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can add items to their shopping list while offline and see them appear locally within 1 second.
- **SC-002**: 100% of queued actions sync successfully within 30 seconds of connectivity being restored (excluding conflicts).
- **SC-003**: Queued actions persist across app restarts with zero data loss.
- **SC-004**: Users can see which items have pending changes without any additional taps or navigation.
- **SC-005**: Conflict resolution produces a consistent final state across all devices within 60 seconds.
- **SC-006**: The offline queue supports at least 200 queued actions without performance degradation.

## Clarifications

### Session 2026-05-13

- Q: What conflict resolution strategy should be used when two users modify the same item while one is offline? → A: Last-write-wins (most recent change by timestamp takes precedence regardless of source)
- Q: How should the system handle automatic retries for failed sync actions? → A: Exponential backoff with max 5 retries (1s, 2s, 4s, 8s, 16s intervals, then mark as failed)
- Q: What condition should trigger offline mode and activate the queue? → A: Hybrid — network connectivity loss OR server reachability failure triggers offline mode
- Q: When should the system clean up queue entries from local storage? → A: Immediate cleanup after successful sync; failed entries remain until manually retried or cleared
- Q: What are the valid state transitions for a queue entry? → A: Linear with retry — pending → syncing → completed; failed → syncing (on retry) → completed or failed

## Assumptions

- Users will primarily experience intermittent connectivity (e.g., inside stores) rather than extended offline periods.
- The existing Supabase Realtime infrastructure (SPEC 007) will be leveraged for detecting connectivity changes; offline detection uses a hybrid approach combining network connectivity checks and server reachability checks.
- The conflict resolution strategy is last-write-wins based on action timestamps; this is deterministic and simple for shopping list scenarios.
- The offline queue is scoped to shopping list actions only; other features (invitations, profile changes) are out of scope for this spec.
- The device has sufficient local storage to persist the queue (typical queue size is < 1MB).
- The existing Isar dependency (mentioned in AGENTS.md) will be used for local persistence of the queue.
