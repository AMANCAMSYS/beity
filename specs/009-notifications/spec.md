# Feature Specification: Notifications

**Feature Branch**: `feature/009-notifications`
**Created**: 2026-05-13
**Status**: Draft
**Input**: User description: "SPEC 09 — Notifications"

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Receive shopping list update notifications (Priority: P1)

As a home member, I want to receive a push notification when another member adds, edits, or completes an item on a shared shopping list, so that I stay informed about list changes without opening the app.

**Why this priority**: Shopping list collaboration is the core value of Beity. Without real-time awareness of changes, members may duplicate purchases or miss items. This is the primary notification use case.

**Independent Test**: Can be fully tested by having two members in a home where one adds/completes an item and verifying the other receives a notification. Delivers immediate collaborative awareness value.

**Acceptance Scenarios**:

1. **Given** a user is a member of a home with a shopping list, **When** another member adds a new item to the list, **Then** the user receives a push notification indicating which item was added and by whom.
2. **Given** a user is a member of a home with a shopping list, **When** another member marks an item as completed, **Then** the user receives a push notification indicating the item was purchased.
3. **Given** a user is a member of a home with a shopping list, **When** another member edits an existing item (name, quantity, or notes), **Then** the user receives a push notification indicating the item was updated.
4. **Given** a user has the app open and is viewing the shopping list, **When** another member makes a change, **Then** the notification is suppressed and the change is shown in real-time on screen instead.

---

### User Story 2 — Receive home and invitation notifications (Priority: P2)

As a user, I want to receive notifications about home membership changes and invitations, so that I can respond to requests and stay aware of who is in my household.

**Why this priority**: Home membership is foundational — users need to know when they are invited and when new members join. This supports the social/collaborative nature of the app.

**Independent Test**: Can be tested by inviting a user to a home and verifying they receive an invitation notification, and by having another user join and verifying members are notified. Delivers home management awareness value.

**Acceptance Scenarios**:

1. **Given** a home owner or admin invites a user, **When** the invitation is sent, **Then** the invited user receives a push notification with the home name and option to accept/decline.
2. **Given** a user receives an invitation notification, **When** they tap the notification, **Then** they are taken to the invitation details screen.
3. **Given** a user is a member of a home, **When** a new member joins the home, **Then** existing members receive a notification indicating who joined.

---

### User Story 3 — Manage notification preferences (Priority: P3)

As a user, I want to control which notifications I receive, so that I am not overwhelmed by alerts I do not care about.

**Why this priority**: Notification fatigue reduces engagement. Users should be able to opt in/out of specific notification types. This improves retention but is not critical for the core notification functionality.

**Independent Test**: Can be tested by toggling notification preferences and verifying that disabled notification types are no longer delivered. Delivers user control and satisfaction value.

**Acceptance Scenarios**:

1. **Given** a user opens notification settings, **When** they view the preferences screen, **Then** they see toggles for each notification category (shopping list updates, home activity, invitations).
2. **Given** a user disables a notification category, **When** an event in that category occurs, **Then** the user does not receive a push notification for that event.
3. **Given** a user re-enables a notification category, **When** an event in that category occurs, **Then** the user receives the notification as expected.

---

### User Story 4 — View notification history (Priority: P4)

As a user, I want to see a history of recent notifications, so that I can catch up on activity I may have missed.

**Why this priority**: Notification history provides a fallback for users who dismiss notifications or were away from their device. Nice to have but not essential for core functionality.

**Independent Test**: Can be tested by generating several notifications and verifying they appear in a notification history list. Delivers value as a catch-up mechanism.

**Acceptance Scenarios**:

1. **Given** a user has received notifications, **When** they open the notification center/inbox, **Then** they see a list of recent notifications with timestamps.
2. **Given** a user taps a notification in the history, **When** they interact with it, **Then** they are taken to the relevant screen (shopping list, home, invitation).
3. **Given** a user has unread notifications, **When** they view the notification center, **Then** unread notifications are visually distinguished from read ones.

---

### Edge Cases

- What happens when a user's device has no internet connection when a notification is sent? (Notifications should be queued by the delivery service and delivered when connectivity is restored.)
- What happens when a user is a member of multiple homes and receives notifications from all of them? (Notifications should clearly indicate which home the activity belongs to.)
- What happens when multiple items are added in quick succession? (Notifications should not spam the user — batch or throttle notifications within a short time window.)
- What happens when a user leaves a home? (They should stop receiving notifications for that home immediately.)
- What happens when a notification is sent to a user who has uninstalled the app? (Delivery failure is expected and should be handled gracefully by the notification service.)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST send push notifications to home members when a shopping list item is added, edited, or completed by another member.
- **FR-002**: System MUST send push notifications to users when they are invited to a home.
- **FR-003**: System MUST send push notifications to home members when a new member joins their home.
- **FR-004**: System MUST suppress push notifications for events that the user is currently viewing in real-time on their screen.
- **FR-005**: System MUST include the home name and the acting user's name in all notification messages.
- **FR-006**: System MUST support Arabic (RTL) notification content in addition to English.
- **FR-007**: System MUST allow users to toggle notifications on/off per category (shopping list updates, home activity, invitations).
- **FR-008**: System MUST persist notification preferences and respect them when sending notifications.
- **FR-009**: System MUST provide a notification history/inbox showing all recent activity events (including those suppressed by real-time viewing) with timestamps, retained for 30 days.
- **FR-010**: System MUST mark notifications as read when the user interacts with them.
- **FR-011**: System MUST stop sending notifications to a user who has left or been removed from a home.
- **FR-012**: System MUST throttle notifications to avoid spamming users when multiple rapid changes occur, batching events within a 2-minute window into a single summary notification.
- **FR-013**: System MUST deliver notifications reliably even when the recipient's device was offline at the time the event occurred.
- **FR-014**: System MUST support deep linking from notifications to the relevant screen (shopping list, home, invitation).
- **FR-015**: System MUST ensure notifications are private — each user can only view their own notifications and notification history.

### Key Entities

- **Notification**: Represents a single notification sent to a user. Key attributes: type (category), title, body, timestamp, read status, home reference, acting user reference, target screen/route. Retained for 30 days then automatically deleted. Visible only to the recipient.
- **Notification Preference**: Represents a user's notification settings. Key attributes: user reference, category (shopping list, home activity, invitations), enabled/disabled state.
- **Notification Category**: A grouping of notification types. Examples: shopping_list, home_activity, invitation.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users receive push notifications within 5 seconds of a triggering event when online.
- **SC-002**: 95% of notifications are successfully delivered to online devices.
- **SC-003**: Users who receive shopping list notifications check the list within 10 minutes on average.
- **SC-004**: Notification preference changes take effect immediately for subsequent events.
- **SC-005**: Users can view notification history and tap to navigate to the relevant screen in under 3 seconds.
- **SC-006**: Notification content displays correctly in both Arabic (RTL) and English (LTR) without layout issues.
- **SC-007**: 80% of users keep at least one notification category enabled after the first week of use (indicates notifications provide value without being intrusive).

## Clarifications

### Session 2026-05-13

- Q: How long should notifications be retained in the system before automatic deletion? → A: 30 days
- Q: Who can see a user's notifications? → A: Private — each user sees only their own notifications; no admin visibility
- Q: What is the default time window for batching rapid-fire notifications? → A: 2 minutes
- Q: Should the notification center show ALL activity events, or only those delivered as push notifications? → A: All events — notification center is a full activity feed, including suppressed real-time events

## Assumptions

- Firebase Cloud Messaging (FCM) is available and configured for the project (per existing tech stack).
- Supabase Realtime is already used for in-app real-time updates and will continue to handle live screen updates.
- Notification delivery infrastructure (FCM tokens, device registration) is handled at the platform level and does not need to be specified here.
- Users have granted notification permissions on their devices. Permission request flows are handled by the app's onboarding or system prompts.
- Notification content is generated server-side or via edge functions to ensure reliability.
- Arabic and English are the two supported languages for notification content from day one.
- The app supports both Android and iOS devices.
