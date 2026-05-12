# Feature Specification: Shopping Lists

**Feature Branch**: `005-shopping-lists`  
**Created**: 2026-05-12  
**Status**: Draft  
**Input**: User description: "Shopping lists management for Beity home management app"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Create Shopping List (Priority: P1)

As a home member, I want to create a new shopping list so that I can organize my shopping needs for a specific occasion or purpose.

**Why this priority**: Shopping lists are the core feature of the app. Without the ability to create lists, no other shopping functionality can work.

**Independent Test**: Can be fully tested by creating a new shopping list and verifying it appears in the list of shopping lists for the home.

**Acceptance Scenarios**:

1. **Given** I am a member of a home, **When** I tap "Create New List" and enter a name, **Then** a new shopping list is created and visible to all home members
2. **Given** I am creating a shopping list, **When** I provide a name and optional description, **Then** the list is saved with my name as the creator
3. **Given** I am not a member of a home, **When** I try to create a shopping list, **Then** I am prompted to join or create a home first

---

### User Story 2 - Add Items to Shopping List (Priority: P1)

As a home member, I want to add items to a shopping list so that I can track what needs to be purchased.

**Why this priority**: Adding items is the primary interaction with shopping lists and essential for the core functionality.

**Independent Test**: Can be tested by adding multiple items to a list and verifying they appear in the list with correct details.

**Acceptance Scenarios**:

1. **Given** I have an open shopping list, **When** I tap "Add Item" and enter item details, **Then** the item appears in the list with quantity and unit
2. **Given** I am adding an item, **When** I select a category from the predefined list, **Then** the item is categorized for easier browsing
3. **Given** I am adding an item, **When** I specify quantity and unit (e.g., 2 kg), **Then** the item displays with the correct measurement
4. **Given** I am adding an item, **When** I type the item name, **Then** I see suggestions from previously added items and common products

---

### User Story 3 - Mark Items as Purchased (Priority: P1)

As a home member, I want to mark items as purchased so that everyone knows what has been bought and what still needs to be purchased.

**Why this priority**: This is essential for coordinating shopping between family members and avoiding duplicate purchases.

**Independent Test**: Can be tested by marking items as purchased and verifying they are visually distinguished from unpurchased items.

**Acceptance Scenarios**:

1. **Given** I am viewing a shopping list, **When** I tap on an unpurchased item, **Then** the item is marked as purchased with a visual indicator (strikethrough, checkmark)
2. **Given** an item is marked as purchased, **When** I tap it again, **Then** the item returns to unpurchased status
3. **Given** multiple home members are viewing the list, **When** one member marks an item as purchased, **Then** all other members see the update in real-time

---

### User Story 4 - Real-time Collaboration (Priority: P2)

As a home member, I want to see changes made by other family members in real-time so that we can coordinate shopping efficiently.

**Why this priority**: Real-time updates prevent duplicate purchases and ensure everyone has the latest information.

**Independent Test**: Can be tested by having two users view the same list and verify that changes from one appear on the other's device immediately.

**Acceptance Scenarios**:

1. **Given** two home members are viewing the same shopping list, **When** one member adds an item, **Then** the other member sees the new item appear without refreshing
2. **Given** two home members are viewing the same shopping list, **When** one member marks an item as purchased, **Then** the other member sees the item marked as purchased in real-time
3. **Given** a home member is offline, **When** they come back online, **Then** they see all changes made while they were offline

---

### User Story 5 - Edit and Remove Items (Priority: P2)

As a home member, I want to edit or remove items from a shopping list so that I can correct mistakes or remove unnecessary items.

**Why this priority**: Users need to be able to correct mistakes and update their shopping needs.

**Independent Test**: Can be tested by editing item details and removing items, then verifying the changes are reflected correctly.

**Acceptance Scenarios**:

1. **Given** I am viewing a shopping list, **When** I swipe left on an item and tap "Edit", **Then** I can modify the item's name, quantity, unit, and category
2. **Given** I am viewing a shopping list, **When** I swipe left on an item and tap "Delete", **Then** the item is removed from the list after confirmation
3. **Given** I am editing an item, **When** I change the quantity, **Then** the updated quantity is visible to all home members

---

### User Story 6 - Shopping List Management (Priority: P2)

As a home member, I want to manage my shopping lists (rename, archive, delete) so that I can keep my lists organized.

**Why this priority**: Users need to manage their lists over time, archiving completed lists and removing unnecessary ones.

**Independent Test**: Can be tested by performing management operations on lists and verifying they work correctly.

**Acceptance Scenarios**:

1. **Given** I am viewing my shopping lists, **When** I swipe left on a list and tap "Rename", **Then** I can enter a new name for the list
2. **Given** I am viewing my shopping lists, **When** I swipe left on a list and tap "Archive", **Then** the list is moved to an archived section
3. **Given** I am the list creator, **When** I swipe left on a list and tap "Delete", **Then** the list is permanently deleted after confirmation
4. **Given** I archived a list, **When** I go to the archived section, **Then** I can restore the list to active status

---

### User Story 7 - Quick Add from Favorites (Priority: P3)

As a home member, I want to quickly add frequently purchased items from a favorites list so that I can build my shopping list faster.

**Why this priority**: This improves efficiency for regular shoppers but is not essential for core functionality.

**Independent Test**: Can be tested by adding items from favorites and verifying they appear in the shopping list.

**Acceptance Scenarios**:

1. **Given** I am viewing a shopping list, **When** I tap "Quick Add", **Then** I see a list of my frequently purchased items
2. **Given** I am viewing my favorites, **When** I tap on an item, **Then** it is added to the current shopping list with default quantity
3. **Given** I have added an item from favorites, **When** I view the item details, **Then** I can adjust the quantity before confirming

---

### User Story 8 - Shopping List Summary (Priority: P3)

As a home member, I want to see a summary of my shopping list so that I can quickly understand what needs to be purchased.

**Why this priority**: A summary view helps users quickly assess their shopping needs without scrolling through the entire list.

**Independent Test**: Can be tested by viewing the summary and verifying it shows the correct information.

**Acceptance Scenarios**:

1. **Given** I am viewing a shopping list, **When** I tap "Summary", **Then** I see a breakdown of items by category
2. **Given** I am viewing the summary, **When** I look at the totals, **Then** I see the number of items purchased vs. total items
3. **Given** I am viewing the summary, **When** I look at the estimated cost, **Then** I see the total estimated cost if prices are available

---

### Edge Cases

- What happens when a user tries to add an item to a list that doesn't exist?
- How does the system handle conflicts when two users edit the same item simultaneously?
- What happens when a user is removed from a home while they have active shopping lists?
- How does the system handle very large shopping lists (100+ items)?
- What happens when a user tries to create a list with a duplicate name?
- How does the system handle network interruptions during real-time sync?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow authenticated users to create new shopping lists within their home
- **FR-002**: System MUST allow users to add items to shopping lists with name, quantity, unit, and category
- **FR-003**: System MUST allow users to mark items as purchased/unpurchased
- **FR-004**: System MUST provide real-time synchronization of list changes across all home members
- **FR-005**: System MUST allow users to edit item details (name, quantity, unit, category)
- **FR-006**: System MUST allow users to remove items from shopping lists
- **FR-007**: System MUST allow users to rename, archive, and delete shopping lists
- **FR-008**: System MUST maintain a history of purchased items for quick re-addition
- **FR-009**: System MUST support Arabic and English languages with RTL layout
- **FR-010**: System MUST enforce role-based permissions (only home members can view/edit lists)
- **FR-011**: System MUST provide offline capability with sync when connection is restored
- **FR-012**: System MUST send notifications when items are added or marked as purchased
- **FR-013**: System MUST allow users to create shopping lists from templates
- **FR-014**: System MUST provide search functionality within shopping lists
- **FR-015**: System MUST support multiple unit types (kg, g, liters, pieces, etc.)

### Key Entities

- **Shopping List**: Represents a collection of items to be purchased. Key attributes: name, description, creator, home_id, status (active/archived), created_at, updated_at
- **Shopping Item**: Represents an individual item in a shopping list. Key attributes: name, quantity, unit, category, is_purchased, purchased_by, purchased_at, notes
- **Item Template**: Represents a frequently used item for quick addition. Key attributes: name, default_quantity, default_unit, category, usage_count

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can create a new shopping list in under 30 seconds
- **SC-002**: Users can add an item to a list in under 15 seconds
- **SC-003**: Real-time updates appear on all devices within 2 seconds
- **SC-004**: 95% of users can complete their shopping list creation on first attempt
- **SC-005**: The app remains responsive with lists containing up to 200 items
- **SC-006**: Users can find and add previously purchased items in under 10 seconds
- **SC-007**: 90% of users report the shopping list feature meets their needs for coordinating family shopping

## Assumptions

- Users have stable internet connectivity for real-time features (offline support is a secondary priority)
- The app will reuse the existing home membership system for permissions
- Categories and units from SPEC 04 will be used for item categorization
- The system will support up to 50 shopping lists per home
- Notifications will use the existing Firebase FCM infrastructure
- The UI will follow the existing Beity design system and Arabic RTL support
