# Feature Specification: Realtime Sync

**Feature Branch**: `007-realtime-sync`  
**Created**: 2026-05-13  
**Status**: Draft  
**Input**: User description: "SPEC 07 — Realtime Sync"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Live Shopping List Updates (Priority: P1)

As a home member, I want to see changes to shopping lists appear instantly on my screen so that I can coordinate shopping with my family in real-time without manually refreshing.

**Why this priority**: Real-time updates are the core value proposition of this feature. Without live updates, family members cannot coordinate effectively and may duplicate purchases.

**Independent Test**: Can be tested by opening the same shopping list on two devices, adding an item on one device, and verifying it appears on the other device within 1 second without any manual refresh.

**Acceptance Scenarios**:

1. **Given** two family members have the same shopping list open, **When** member A adds an item, **Then** member B sees the new item appear on their screen within 1 second
2. **Given** two family members have the same shopping list open, **When** member A marks an item as purchased, **Then** member B sees the item marked as purchased on their screen within 1 second
3. **Given** two family members have the same shopping list open, **When** member A edits an item's quantity, **Then** member B sees the updated quantity within 1 second
4. **Given** two family members have the same shopping list open, **When** member A deletes an item, **Then** the item disappears from member B's screen within 1 second
5. **Given** I am viewing a shopping list, **When** another member creates a new list in the same home, **Then** the new list appears in my lists view within 1 second

---

### User Story 2 - Online Presence Indicators (Priority: P2)

As a home member, I want to see which family members are currently viewing the same shopping list so that I know who is actively shopping or planning.

**Why this priority**: Presence indicators help family members avoid conflicts and coordinate better. They are valuable but not essential for basic real-time functionality.

**Independent Test**: Can be tested by opening a shopping list on two devices with different users and verifying that each device shows the other user's presence indicator.

**Acceptance Scenarios**:

1. **Given** I am viewing a shopping list, **When** another member opens the same list, **Then** I see a presence indicator showing they are viewing the list
2. **Given** I am viewing a shopping list with another member present, **When** that member leaves the list, **Then** their presence indicator disappears within 5 seconds
3. **Given** multiple members are viewing the same list, **When** I open the list, **Then** I see all currently present members displayed as avatars or initials

---

### User Story 3 - Home-Level Realtime Updates (Priority: P2)

As a home member, I want to see changes to home membership, invitations, and categories reflected in real-time so that I don't need to refresh the app to see new members or categories.

**Why this priority**: Home-level updates happen less frequently than shopping list changes, but still benefit from real-time sync for a seamless experience.

**Independent Test**: Can be tested by having one member create a category while another member is on the categories screen, and verifying the new category appears without refresh.

**Acceptance Scenarios**:

1. **Given** I am viewing the home members list, **When** a new member joins the home, **Then** they appear in my members list within 2 seconds
2. **Given** I am viewing categories, **When** another member creates a new category, **Then** the new category appears in my categories list within 2 seconds
3. **Given** I am viewing the home screen, **When** my role changes (e.g., from member to admin), **Then** my permissions update immediately without requiring a re-login

---

### User Story 4 - Connection Status Awareness (Priority: P3)

As a home member, I want to know when my device loses connection to the server so that I understand why updates may have stopped and can take appropriate action.

**Why this priority**: Connection status awareness prevents confusion when real-time updates stop. It is important for user trust but not required for core functionality.

**Independent Test**: Can be tested by enabling airplane mode while viewing a shopping list and verifying that a connection status indicator appears.

**Acceptance Scenarios**:

1. **Given** I am viewing a shopping list with real-time updates, **When** my device loses internet connection, **Then** I see a "Disconnected" indicator within 3 seconds
2. **Given** I see a "Disconnected" indicator, **When** my connection is restored, **Then** the indicator disappears and any missed updates are fetched automatically
3. **Given** I am offline, **When** I make changes to a shopping list, **Then** the changes are queued locally and synced when connection is restored

---

### Edge Cases

- What happens when two members mark the same item as purchased at the exact same time?
- How does the system handle a member who rapidly switches between lists (subscribing/unsubscribing from channels)?
- What happens when the real-time connection drops and reconnects multiple times in quick succession?
- How does the system handle a member who has the app backgrounded for an extended period?
- What happens when a member is removed from a home while they have a list open?
- How does the system handle a very large shopping list (100+ items) with frequent updates from multiple members?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST deliver changes to shopping list items to all connected devices within 1 second under normal network conditions
- **FR-002**: System MUST display which home members are currently viewing the same shopping list; presence is only visible when viewing the identical list (not at home level)
- **FR-003**: System MUST automatically reconnect and fetch missed updates when a device regains connectivity after being offline
- **FR-004**: System MUST queue local changes made while offline and synchronize them when connectivity is restored; queued changes are discarded with a warning on logout or app data clear
- **FR-005**: System MUST handle simultaneous edits to the same item by applying the most recent change (last-write-wins); the overwritten user MUST see a brief toast notification ("Item updated by [name]") and the changed item MUST be visually highlighted for 3 seconds
- **FR-006**: System MUST subscribe to real-time channels only for data the user is actively viewing (not all home data at once)
- **FR-007**: System MUST unsubscribe from real-time channels when the user navigates away from a screen
- **FR-008**: System MUST display a connection status indicator when the device loses connection to the server; upon reconnection, a "Syncing..." progress indicator MUST appear at the top of the active list until missed updates are fetched
- **FR-009**: System MUST sync home-level changes (members, roles, categories) to all connected devices
- **FR-010**: System MUST handle channel subscription errors gracefully without crashing the app
- **FR-011**: System MUST clean up real-time subscriptions when a user logs out
- **FR-012**: System MUST handle the case where a user is removed from a home while actively viewing data by redirecting them to the homes list and displaying a dialog: "You have been removed from [home name]"

### Key Entities

- **Realtime Channel**: Represents a subscription to live changes for a specific data scope (e.g., a shopping list, a home). Has a lifecycle (subscribe, listen, unsubscribe).
- **Presence**: Represents an active user viewing a specific resource. Contains user identity and the resource being viewed.
- **Sync Queue**: Represents pending changes made while offline. Contains the operation, target entity, and timestamp.
- **Connection State**: Represents the current connectivity status of the device (connected, disconnected, reconnecting).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Changes made by one family member appear on all other members' devices within 1 second under normal network conditions
- **SC-002**: Users can view a shopping list on two devices simultaneously and see synchronized content at all times
- **SC-003**: When a device loses and regains connectivity, all missed updates are fetched and displayed within 3 seconds of reconnection
- **SC-004**: Users can successfully make changes while offline, and those changes sync within 5 seconds of regaining connectivity
- **SC-005**: Presence indicators accurately reflect who is viewing a list, with a maximum 5-second delay for detecting joins and leaves
- **SC-006**: The app remains responsive during real-time updates, with no visible UI freezing or frame drops
- **SC-007**: Battery consumption does not increase by more than 10% compared to the app without real-time features during typical usage

## Assumptions

- Supabase Realtime service is available and reliable for the target regions
- Users have a stable internet connection for the majority of their app usage
- The primary use case is a small family group (2-10 members per home), not large organizations
- Shopping lists are the highest-priority data for real-time sync; other features (inventory, expenses, tasks) will be addressed in future specs
- The app already uses Supabase as the backend, and Supabase Realtime is included in the current plan
- Conflict resolution uses last-write-wins strategy; more sophisticated merging is out of scope for this spec
- Offline support is limited to queuing changes and syncing on reconnect; full offline-first architecture with local database (Isar) is deferred to a future spec
- Push notifications for background updates are out of scope for this spec and will be addressed separately

## Clarifications

### Session 2026-05-13

- Q: If a user logs out or force-closes the app while there are unsynced changes in the queue, what should happen? → A: Discard queued changes with a warning before logout/clear
- Q: When a user's edit is overwritten by another member's concurrent edit, should the user be notified? → A: Brief toast notification ("Item updated by [name]") plus visual highlight on the changed item for 3 seconds
- Q: When a user is removed from a home while actively viewing data, where should they be redirected? → A: Redirect to homes list with a dialog: "You have been removed from [home name]"
- Q: When the device reconnects and is fetching missed updates, what should the user see? → A: A linear progress bar or spinner at the top of the list with "Syncing..." text
- Q: Should presence indicators be visible only when viewing the same shopping list, or also at the home level? → A: Same-list only; presence is shown only when viewing the identical shopping list
