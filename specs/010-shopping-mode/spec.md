# Feature Specification: Shopping Mode

**Feature Branch**: `010-shopping-mode`  
**Created**: 2026-05-13  
**Status**: Draft  
**Input**: User description: "Shopping Mode — a dedicated, fast, distraction-free interface for actively shopping at a store"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Enter Shopping Mode (Priority: P1)

As a home member, I want to enter a dedicated shopping mode from a shopping list so that I have a focused, fast interface while physically shopping at a store.

**Why this priority**: The entire feature depends on the ability to enter shopping mode. This is the entry point that enables all other shopping mode interactions.

**Independent Test**: Can be fully tested by opening a shopping list, tapping a "Start Shopping" button, and verifying the UI switches to a simplified, large-touch-target view.

**Acceptance Scenarios**:

1. **Given** I am viewing a shopping list with items, **When** I tap "Start Shopping", **Then** the UI transitions to shopping mode with large item cards and simplified controls
2. **Given** I am viewing an empty shopping list, **When** I tap "Start Shopping", **Then** I see a message that the list is empty with a prompt to add items first
3. **Given** I am in shopping mode, **When** the screen rotates or I switch apps and return, **Then** shopping mode remains active with the same scroll position and state

---

### User Story 2 - Mark Items as Purchased in Shopping Mode (Priority: P1)

As a home member, I want to mark items as purchased with a single, large tap target so that I can quickly check off items while holding groceries or pushing a cart.

**Why this priority**: Marking items purchased is the primary action during shopping. The interface must be optimized for speed and one-handed use.

**Independent Test**: Can be tested by tapping an item card in shopping mode and verifying it moves to the purchased section with visual feedback.

**Acceptance Scenarios**:

1. **Given** I am in shopping mode viewing unpurchased items, **When** I tap anywhere on an item card, **Then** the item is marked as purchased with a checkmark animation and moves to the purchased section
2. **Given** I have marked an item as purchased, **When** I tap it again, **Then** it returns to the unpurchased section
3. **Given** I am marking items, **When** I mark an item, **Then** the change syncs to other home members in real-time
4. **Given** I mark an item as purchased, **When** I look at the item, **Then** I see who purchased it and when

---

### User Story 3 - Browse Items by Category (Priority: P1)

As a home member, I want items grouped by category in shopping mode so that I can follow the store layout and shop efficiently aisle by aisle.

**Why this priority**: Category grouping is the primary navigation method in shopping mode and directly impacts shopping speed.

**Independent Test**: Can be tested by entering shopping mode with items in multiple categories and verifying they appear under collapsible category headers.

**Acceptance Scenarios**:

1. **Given** I am in shopping mode, **When** I view the item list, **Then** items are grouped under category headers that match the store sections
2. **Given** items are grouped by category, **When** I tap a category header, **Then** the group collapses or expands
3. **Given** all items in a category are purchased, **When** I view the list, **Then** the category group is collapsed by default and shows a completion indicator
4. **Given** I have items without a category, **When** I view the list, **Then** they appear under an "Other" group at the end

---

### User Story 4 - Add Items Quickly in Shopping Mode (Priority: P1)

As a home member, I want to add items quickly while in shopping mode so that I can capture items I forgot to add before shopping.

**Why this priority**: Users frequently discover they forgot items while shopping. The add flow must be extremely fast to maintain the shopping rhythm.

**Independent Test**: Can be tested by tapping an add button in shopping mode, typing an item name, and verifying the item appears in the list immediately.

**Acceptance Scenarios**:

1. **Given** I am in shopping mode, **When** I tap the floating add button, **Then** a minimal add-item overlay appears with a large text field and autocomplete suggestions
2. **Given** I am adding an item in shopping mode, **When** I type a name and tap "Add", **Then** the item is added to the list and the overlay closes automatically
3. **Given** I am adding an item, **When** I type a name that matches an existing template, **Then** I see the template suggestion with default quantity and unit
4. **Given** I am adding an item, **When** I submit the item, **Then** I can immediately start typing the next item without re-opening the add overlay

---

### User Story 5 - See Shopping Progress (Priority: P2)

As a home member, I want to see my shopping progress at a glance so that I know how much is left to buy.

**Why this priority**: A progress indicator helps users pace their shopping and know when they are done.

**Independent Test**: Can be tested by marking items as purchased and verifying the progress indicator updates correctly.

**Acceptance Scenarios**:

1. **Given** I am in shopping mode, **When** I look at the top of the screen, **Then** I see a progress bar and count (e.g., "12 of 20 items purchased")
2. **Given** I have purchased all items, **When** I view the progress, **Then** I see a completion message with an option to exit shopping mode
3. **Given** I am viewing progress, **When** a family member marks an item on their device, **Then** my progress updates in real-time

---

### User Story 6 - Search Items in Shopping Mode (Priority: P2)

As a home member, I want to search for items within shopping mode so that I can quickly find specific items in long lists.

**Why this priority**: Long lists can have 50+ items. Search helps users find items without scrolling through the entire list.

**Independent Test**: Can be tested by entering a search term and verifying only matching items are displayed.

**Acceptance Scenarios**:

1. **Given** I am in shopping mode, **When** I tap the search icon and type a keyword, **Then** only items matching the keyword are displayed
2. **Given** I have applied a search, **When** I clear the search field, **Then** all items are displayed again
3. **Given** I am searching, **When** I mark a search result as purchased, **Then** the item is marked and the search results update

---

### User Story 7 - Exit Shopping Mode (Priority: P2)

As a home member, I want to exit shopping mode when I am done shopping so that I return to the normal list view.

**Why this priority**: Users need a clear way to return to the standard interface after shopping.

**Independent Test**: Can be tested by tapping an exit button and verifying the UI returns to the normal shopping list view.

**Acceptance Scenarios**:

1. **Given** I am in shopping mode, **When** I tap the "Done Shopping" button, **Then** I see a summary showing: total items purchased vs. total count, list of purchased items grouped by category, and who purchased each item — then return to the normal list view
2. **Given** I am in shopping mode with unpurchased items remaining, **When** I tap "Done Shopping", **Then** I see a confirmation asking if I want to exit with items still unpurchased
3. **Given** I am in shopping mode, **When** I tap the back button or swipe back, **Then** I am prompted to confirm exit before leaving shopping mode

---

### User Story 8 - Shopping Mode Stays Awake (Priority: P3)

As a home member, I want the screen to stay awake while in shopping mode so that I do not have to keep unlocking my phone while shopping.

**Why this priority**: This is a convenience feature that improves the shopping experience but is not essential.

**Independent Test**: Can be tested by entering shopping mode and verifying the screen does not dim or lock automatically.

**Acceptance Scenarios**:

1. **Given** I am in shopping mode, **When** I leave the phone unattended, **Then** the screen stays on until I exit shopping mode
2. **Given** I exit shopping mode, **When** I return to the normal app, **Then** the standard screen timeout behavior is restored

---

### User Story 9 - Quick Item Quantity Adjustment (Priority: P3)

As a home member, I want to quickly adjust item quantities in shopping mode so that I can update amounts without navigating to a separate edit screen.

**Why this priority**: Quantity adjustments are common during shopping but not as frequent as marking items purchased.

**Independent Test**: Can be tested by tapping a quantity control on an item card and verifying the quantity updates.

**Acceptance Scenarios**:

1. **Given** I am in shopping mode, **When** I tap the quantity indicator on an item card, **Then** I see inline +/- controls to adjust the quantity
2. **Given** I am adjusting quantity, **When** I tap + or -, **Then** the quantity changes by one unit and the change syncs in real-time
3. **Given** I have adjusted a quantity, **When** I dismiss the controls, **Then** the new quantity is displayed on the item card

---

### Edge Cases

- What happens when a user's phone battery dies while in shopping mode? → Shopping progress is preserved; the user can re-enter shopping mode and see the same state
- How does the system handle a network interruption while in shopping mode? → Items can still be marked as purchased locally; changes sync when the connection is restored
- What happens when another family member edits the list while the user is in shopping mode? → Changes appear in real-time; if an item is deleted, it disappears from shopping mode with a brief notification
- How does the system handle very long lists (200+ items) in shopping mode? → Lists are virtualized for performance; category grouping helps manage long lists
- What happens when a category has no unpurchased items left? → The category is collapsed and shows a checkmark to indicate completion
- What happens when the user receives a phone call while in shopping mode? → Shopping mode remains active after the call ends

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide a "Start Shopping" button on shopping list screens that activates shopping mode
- **FR-002**: System MUST display items in a large-card layout optimized for quick identification and tapping
- **FR-003**: System MUST allow users to mark items as purchased with a single tap on the item card
- **FR-004**: System MUST group items by category with collapsible headers
- **FR-005**: System MUST automatically collapse categories where all items are purchased
- **FR-006**: System MUST provide a floating action button to add new items while in shopping mode
- **FR-007**: System MUST display a minimal add-item overlay with autocomplete suggestions for quick entry
- **FR-008**: System MUST allow consecutive item additions without re-opening the add overlay
- **FR-009**: System MUST display a progress indicator showing purchased count vs. total count
- **FR-010**: System MUST provide search functionality within shopping mode
- **FR-011**: System MUST provide a "Done Shopping" button that shows a summary and exits shopping mode
- **FR-012**: System MUST prompt for confirmation when exiting with unpurchased items remaining
- **FR-013**: System MUST keep the screen awake while shopping mode is active
- **FR-014**: System MUST provide inline quantity adjustment controls on item cards
- **FR-015**: System MUST synchronize all changes in real-time across home members
- **FR-016**: System MUST support offline operation with sync when connection is restored
- **FR-017**: System MUST support Arabic and English languages with RTL layout in shopping mode
- **FR-018**: System MUST return to normal list view when shopping mode is exited
- **FR-019**: System MUST preserve shopping mode state across app backgrounding and screen rotation
- **FR-020**: System MUST show purchased items at the bottom of each category group (sunk within their category)

### Key Entities

- **Shopping Mode Session**: Represents a shopping session (persisted for history). Key attributes: list_id, started_at, ended_at, items_purchased_count, items_total_count, user_id, home_id
- **Shopping Item** (existing): Used in shopping mode with the same attributes as the standard shopping item, but displayed in an optimized layout

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can mark an item as purchased in under 2 seconds with a single tap
- **SC-002**: Users can add a new item in shopping mode in under 10 seconds
- **SC-003**: Shopping mode UI remains responsive with lists of up to 200 items
- **SC-004**: 95% of users can navigate shopping mode without instructions on first use
- **SC-005**: Real-time updates appear on all devices within 2 seconds during shopping mode
- **SC-006**: 90% of users report shopping mode is faster than using the standard list view for shopping
- **SC-007**: Users can complete an entire shopping trip without leaving shopping mode
- **SC-008**: Screen-awake functionality prevents screen timeout during 100% of shopping sessions

## Assumptions

- Shopping lists and items from SPEC 005 and SPEC 006 are already implemented
- Categories from SPEC 004 are available for item grouping
- Real-time sync uses Supabase Realtime subscriptions from SPEC 007
- The home membership and permission system from SPEC 002/003 is in place
- Shopping mode is a UI layer over existing shopping list data — no new data model is required beyond the session tracking
- Multiple home members can be in shopping mode on the same list simultaneously; changes sync in real-time across all active sessions
- The screen-awake feature uses standard platform screen-keep-awake APIs
- The UI follows the existing Beity design system with Arabic RTL support
- Shopping mode does not include barcode scanning, price comparison, or store-specific layouts in this version

## Clarifications

### Session 2026-05-13

- Q: Where should purchased items appear in shopping mode? → A: Bottom of each category group (purchased items sink within their category)
- Q: Should shopping sessions be stored for history/analytics? → A: Yes, persisted in the database for history and analytics
- Q: Can multiple home members shop the same list at the same time? → A: Yes, multiple simultaneous sessions with real-time sync
- Q: What should the shopping summary show on exit? → A: Count + list of purchased items grouped by category + who purchased each item
