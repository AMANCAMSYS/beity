# Feature Specification: Activity Logs

**Feature Branch**: `008-activity-logs`  
**Created**: 2026-05-13  
**Status**: Draft  
**Input**: User description: "Activity Logs — tracking and displaying actions performed by home members on shared household resources for transparency and accountability"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - View Activity Feed for a Home (Priority: P1)

As a home member, I want to see a chronological feed of recent activities in my home so that I can stay informed about what other members are doing.

**Why this priority**: The core value of activity logs is providing visibility into household actions. Without a viewable feed, the feature has no purpose.

**Independent Test**: Can be fully tested by performing actions in a home (adding items, marking purchased, editing lists) and verifying they appear in the activity feed with correct actor, action, and timestamp.

**Acceptance Scenarios**:

1. **Given** I am a member of a home, **When** I open the activity log screen, **Then** I see a chronological list of recent actions performed by all home members
2. **Given** there are multiple activities, **When** I view the feed, **Then** activities are sorted from newest to oldest
3. **Given** I am viewing an activity entry, **When** I look at the details, **Then** I see who performed the action, what was done, on which resource, and when
4. **Given** no activities exist yet for a home, **When** I open the activity log, **Then** I see an empty state explaining that activities will appear as members interact with shared resources

---

### User Story 2 - Track Shopping List Changes (Priority: P1)

As a home member, I want to see when shopping lists are created, renamed, archived, or deleted so that I can understand how lists are being managed.

**Why this priority**: Shopping lists are the primary shared resource. Tracking changes to lists is essential for accountability.

**Independent Test**: Can be tested by creating, renaming, archiving, and deleting shopping lists, then verifying each action appears in the activity log.

**Acceptance Scenarios**:

1. **Given** a home member creates a new shopping list, **When** I view the activity log, **Then** I see an entry showing "[Member] created list [List Name]"
2. **Given** a home member renames a shopping list, **When** I view the activity log, **Then** I see an entry showing "[Member] renamed list from [Old Name] to [New Name]"
3. **Given** a home member archives a shopping list, **When** I view the activity log, **Then** I see an entry showing "[Member] archived list [List Name]"
4. **Given** a home member deletes a shopping list, **When** I view the activity log, **Then** I see an entry showing "[Member] deleted list [List Name]"

---

### User Story 3 - Track Shopping Item Changes (Priority: P1)

As a home member, I want to see when items are added, edited, marked as purchased, or deleted from shopping lists so that I can track shopping progress.

**Why this priority**: Item-level tracking is the most granular and useful log for daily shopping coordination.

**Independent Test**: Can be tested by adding, editing, purchasing, and deleting items, then verifying each action appears in the activity log with the correct list context.

**Acceptance Scenarios**:

1. **Given** a home member adds an item to a shopping list, **When** I view the activity log, **Then** I see an entry showing "[Member] added [Item Name] to [List Name]"
2. **Given** a home member edits an item, **When** I view the activity log, **Then** I see an entry showing "[Member] updated [Item Name] in [List Name]"
3. **Given** a home member marks an item as purchased, **When** I view the activity log, **Then** I see an entry showing "[Member] purchased [Item Name] from [List Name]"
4. **Given** a home member deletes an item, **When** I view the activity log, **Then** I see an entry showing "[Member] removed [Item Name] from [List Name]"

---

### User Story 4 - Track Membership Changes (Priority: P2)

As a home member, I want to see when members join, leave, or have their roles changed so that I can track who has access to the home.

**Why this priority**: Membership changes affect who can see and modify shared resources. Tracking these changes is important for security awareness.

**Independent Test**: Can be tested by inviting members, accepting invitations, changing roles, and removing members, then verifying each action appears in the activity log.

**Acceptance Scenarios**:

1. **Given** a new member joins the home, **When** I view the activity log, **Then** I see an entry showing "[Member] joined the home"
2. **Given** a member's role is changed, **When** I view the activity log, **Then** I see an entry showing "[Admin] changed [Member]'s role from [Old Role] to [New Role]"
3. **Given** a member leaves or is removed from the home, **When** I view the activity log, **Then** I see an entry showing "[Member] left the home" or "[Admin] removed [Member] from the home"

---

### User Story 5 - Filter Activity Logs (Priority: P2)

As a home member, I want to filter the activity feed by action type or member so that I can quickly find specific activities.

**Why this priority**: As the log grows, finding specific actions becomes difficult without filtering.

**Independent Test**: Can be tested by applying filters (by member, by action type) and verifying only matching entries are shown.

**Acceptance Scenarios**:

1. **Given** I am viewing the activity log, **When** I select a specific member from a filter, **Then** I only see actions performed by that member
2. **Given** I am viewing the activity log, **When** I select an action type filter (e.g., "purchases", "list changes"), **Then** I only see actions of that type
3. **Given** I have applied a filter, **When** I clear the filter, **Then** all activities are displayed again

---

### User Story 6 - View List-Level Activity (Priority: P2)

As a home member, I want to view activity logs scoped to a specific shopping list so that I can see the history of changes for that list without noise from other lists.

**Why this priority**: When managing a specific list, users need focused context. This complements the home-level feed for overall awareness.

**Independent Test**: Can be tested by opening a shopping list's activity view and verifying only actions related to that list are shown.

**Acceptance Scenarios**:

1. **Given** I am viewing a shopping list, **When** I open the activity view for that list, **Then** I see only actions related to that list (items added, purchased, edited, deleted, list renamed, etc.)
2. **Given** I am viewing a list-level activity log, **When** a new action occurs on that list, **Then** the entry appears in real-time
3. **Given** I am viewing a list-level activity log, **When** I tap on an entry for a deleted item, **Then** I see the action details but the item link is disabled

---

### User Story 7 - View Activity Details (Priority: P3)

As a home member, I want to tap on an activity entry to see more details so that I can understand exactly what changed.

**Why this priority**: Detail view provides deeper context but the summary in the feed is sufficient for most use cases.

**Independent Test**: Can be tested by tapping an activity entry and verifying the detail view shows additional context such as before/after values for edits.

**Acceptance Scenarios**:

1. **Given** I am viewing the activity log, **When** I tap on an activity entry, **Then** I see a detail view with the full action description, before/after values (for edits), and a link to the affected resource
2. **Given** I am viewing details for a deleted resource, **When** I look at the detail view, **Then** I see the action details but the resource link is disabled or shows "Resource no longer exists"

---

### Edge Cases

- What happens when a user is removed from a home? → Their past activity entries remain visible to other home members for audit purposes
- How does the system handle very high activity volumes (100+ actions per day)? → Display the most recent 500 entries with infinite scroll pagination; older entries are still stored but not shown in the default view
- What happens when a resource referenced in a log entry is deleted? → The log entry still displays with the resource name at the time of the action; no broken links
- How does the system handle activity logging when the network is offline? → Activities are generated server-side via database triggers; offline actions are logged when synced
- What happens when a user's name changes after they performed actions? → Activity logs display the user's name at the time the action was performed (denormalized)

## Clarifications

### Session 2026-05-13

- Q: Should admins/owners have special privileges regarding activity logs (e.g., additional events, management)? → A: No — all home members see the same activity log with no admin distinction
- Q: Should invitation events be tracked in the activity log? → A: Only log accepted invitations (when someone actually joins), not sent or declined
- Q: Should the activity feed update in real-time while the user is viewing it? → A: Yes — new entries appear in real-time without refreshing
- Q: Should users be able to view activity logs scoped to a single shopping list? → A: Yes — both home-level feed (all activity) and list-level view (filtered to that list)
- Q: Should rapid sequential actions be grouped into batch log entries? → A: No — each action generates a separate log entry with no grouping

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST record an activity log entry whenever a home member creates, updates, or deletes a shopping list
- **FR-002**: System MUST record an activity log entry whenever a home member adds, edits, purchases, unpurchases, or deletes a shopping item
- **FR-003**: System MUST record an activity log entry whenever a home member joins, leaves, is added, is removed, has their role changed, or accepts an invitation
- **FR-004**: System MUST store the actor (who), action type, target entity, entity name, and timestamp for each log entry
- **FR-005**: System MUST scope activity logs to a home — only members of that home can view its logs; all members (including admins/owners) see the same log with no role-based visibility differences
- **FR-006**: System MUST display activity logs in reverse chronological order (newest first)
- **FR-007**: System MUST allow members to filter logs by actor and action type
- **FR-008**: System MUST preserve activity log entries even when the referenced resource is deleted
- **FR-009**: System MUST preserve the actor's display name at the time of the action (denormalized)
- **FR-010**: System MUST display an empty state when no activities exist for a home
- **FR-011**: System MUST NOT allow members to edit or delete activity log entries
- **FR-012**: System MUST support Arabic and English languages with RTL layout for all log UI
- **FR-013**: System MUST paginate activity logs, showing the most recent entries first with infinite scroll
- **FR-014**: System MUST generate activity log entries server-side (via database triggers) to ensure consistency
- **FR-015**: System MUST display new activity log entries in real-time while the feed is open, without requiring a manual refresh
- **FR-016**: System MUST provide a list-level activity view showing only actions related to a specific shopping list
- **FR-017**: System MUST generate a separate log entry for each individual action — rapid sequential actions must not be grouped into batch entries

### Key Entities

- **Activity Log**: Represents a single action performed by a home member. Key attributes: id, home_id, actor_id, actor_name, action_type, target_entity_type, target_entity_id, target_entity_name, metadata (JSON for before/after values), created_at
- **Action Type (enum)**: list_created, list_renamed, list_archived, list_deleted, item_added, item_updated, item_purchased, item_unpurchased, item_deleted, member_joined, member_left, member_removed, member_role_changed, invitation_accepted

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can view the activity feed for their home within 1 second of opening the screen
- **SC-002**: Activity log entries appear in the feed within 3 seconds of the action being performed
- **SC-003**: 95% of users can find a specific activity using filters in under 10 seconds
- **SC-004**: The activity feed remains responsive and scrollable with up to 500 entries loaded
- **SC-005**: 90% of home members report that activity logs help them understand what is happening in their home
- **SC-006**: Activity log entries accurately reflect 100% of user-initiated actions on shopping lists, items, and membership

## Assumptions

- Activity logs are generated server-side via PostgreSQL database triggers, not by the application layer
- The home membership and permission system from SPEC 02/03 is in place for access control
- Real-time subscription from SPEC 07 can be used to push new log entries to the UI
- Activity logs are append-only — entries are never updated or deleted by users
- Denormalizing the actor's display name into the log entry is acceptable for historical accuracy
- Activity log data grows indefinitely; no automatic purging or retention policy for MVP
- The UI follows the existing Beity design system with Arabic RTL support
