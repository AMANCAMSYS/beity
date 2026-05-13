# Feature Specification: Shopping Items

**Feature Branch**: `006-shopping-items`  
**Created**: 2026-05-12  
**Status**: Draft  
**Input**: User description: "Shopping Items — managing individual items within shopping lists including adding, editing, purchasing, searching, and template-based quick-add"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Add Item to Shopping List (Priority: P1)

As a home member, I want to add items to my shopping list so that I can track what needs to be purchased.

**Why this priority**: Adding items is the primary interaction within a shopping list. Without this, the list has no value.

**Independent Test**: Can be fully tested by opening a shopping list, adding an item with name/quantity/unit, and verifying it appears in the list.

**Acceptance Scenarios**:

1. **Given** I have an open shopping list, **When** I tap the "Add Item" button and enter a name, **Then** the item appears at the bottom of the list
2. **Given** I am adding an item, **When** I specify quantity and unit (e.g., 2 kg), **Then** the item displays with the correct measurement
3. **Given** I am adding an item, **When** I select a category, **Then** the item is grouped under that category in the list
4. **Given** I am adding an item, **When** I type the item name, **Then** I see autocomplete suggestions from item templates and previously added items
5. **Given** I am adding an item, **When** I leave the name empty and try to save, **Then** the system prevents saving and shows a validation error
6. **Given** I am adding an item with a name that already exists in the list, **When** I try to save, **Then** the system shows a warning "Item already exists, add anyway?" and allows me to confirm or cancel

---

### User Story 2 - Mark Items as Purchased (Priority: P1)

As a home member, I want to mark items as purchased so that everyone knows what has been bought and what still needs to be purchased.

**Why this priority**: This is essential for coordinating shopping between family members and avoiding duplicate purchases.

**Independent Test**: Can be tested by tapping an item to mark it purchased, verifying visual feedback (strikethrough/checkmark), and confirming the change syncs to other devices.

**Acceptance Scenarios**:

1. **Given** I am viewing a shopping list, **When** I tap on an unpurchased item, **Then** the item is marked as purchased with a visual indicator (strikethrough, checkmark)
2. **Given** an item is marked as purchased, **When** I tap it again, **Then** the item returns to unpurchased status
3. **Given** multiple home members are viewing the list, **When** one member marks an item as purchased, **Then** all other members see the update in real-time
4. **Given** an item is marked as purchased, **When** I view item details, **Then** I can see who purchased it and when

---

### User Story 3 - Edit Item Details (Priority: P1)

As a home member, I want to edit item details so that I can correct mistakes or update information.

**Why this priority**: Users frequently need to adjust quantities, fix typos, or change categories after initially adding an item.

**Independent Test**: Can be tested by editing an item's name, quantity, unit, and category, then verifying changes are saved and synced.

**Acceptance Scenarios**:

1. **Given** I am viewing a shopping list, **When** I long-press or swipe on an item and select "Edit", **Then** I can modify the item's name, quantity, unit, category, price, and notes
2. **Given** I am editing an item, **When** I change the quantity, **Then** the updated quantity is visible to all home members
3. **Given** I am editing an item, **When** I clear the name field and try to save, **Then** the system prevents saving and shows a validation error
4. **Given** two users edit the same item simultaneously, **When** both save, **Then** the last write wins and all users see the latest version

---

### User Story 4 - Delete Items (Priority: P2)

As a home member, I want to delete items from a shopping list so that I can remove unnecessary or duplicate entries.

**Why this priority**: Users need to clean up lists but this is less frequent than adding or editing.

**Independent Test**: Can be tested by deleting an item and verifying it is removed from the list for all members.

**Acceptance Scenarios**:

1. **Given** I am viewing a shopping list, **When** I swipe left on an item and tap "Delete", **Then** the item is removed from the list after confirmation
2. **Given** I delete an item, **When** other members view the list, **Then** the item is also removed from their view in real-time
3. **Given** I accidentally delete an item, **When** I see the confirmation snackbar, **Then** I can tap "Undo" to restore the item within 5 seconds

---

### User Story 5 - Search and Filter Items (Priority: P2)

As a home member, I want to search and filter items within a shopping list so that I can quickly find specific items in long lists.

**Why this priority**: Lists can grow to 50+ items during large shopping trips. Search improves usability significantly.

**Independent Test**: Can be tested by adding multiple items, searching for a specific name, and verifying only matching items are shown.

**Acceptance Scenarios**:

1. **Given** I am viewing a shopping list with multiple items, **When** I tap the search icon and type a keyword, **Then** only items matching the keyword are displayed
2. **Given** I have items in multiple categories, **When** I select a category filter, **Then** only items in that category are shown
3. **Given** I have applied a search or filter, **When** I clear the search field or filter, **Then** all items are displayed again

---

### User Story 6 - Organize Items by Category (Priority: P2)

As a home member, I want items to be automatically grouped by category so that I can shop efficiently by following the store layout.

**Why this priority**: Category grouping reduces shopping time by allowing users to complete one section before moving to the next.

**Independent Test**: Can be tested by adding items with different categories and verifying they appear grouped under category headers.

**Acceptance Scenarios**:

1. **Given** I am viewing a shopping list, **When** items have categories assigned, **Then** items are grouped under collapsible category headers
2. **Given** I am viewing a category group, **When** I tap the category header, **Then** the group collapses or expands
3. **Given** I add an item without a category, **When** I view the list, **Then** the item appears under an "Uncategorized" group

---

### User Story 7 - Quick-Add from Templates (Priority: P2)

As a home member, I want to quickly add frequently purchased items from a template list so that I can build my shopping list faster.

**Why this priority**: Families buy the same items regularly. Templates reduce repetitive data entry.

**Independent Test**: Can be tested by opening the template picker, selecting an item, and verifying it is added to the list with pre-filled details.

**Acceptance Scenarios**:

1. **Given** I am viewing a shopping list, **When** I tap "Quick Add", **Then** I see a list of frequently used item templates sorted by usage count
2. **Given** I am viewing templates, **When** I tap on a template, **Then** an item is added to the list with the template's default name, quantity, unit, and category
3. **Given** a template is used, **When** the item is added, **Then** the template's usage count is incremented for future sorting
4. **Given** I have no templates yet, **When** I open Quick Add, **Then** I see an empty state with a prompt to start adding items to build templates

---

### User Story 8 - Track Item Prices (Priority: P3)

As a home member, I want to optionally enter prices for items so that I can estimate the total shopping cost.

**Why this priority**: Price tracking is useful for budgeting but not essential for the core shopping coordination experience.

**Independent Test**: Can be tested by entering a price for an item and verifying it appears in the list and contributes to the total.

**Acceptance Scenarios**:

1. **Given** I am adding or editing an item, **When** I enter a price, **Then** the price is saved and displayed on the item
2. **Given** multiple items have prices, **When** I view the list, **Then** I see a running total of unpurchased items at the bottom of the list
3. **Given** I am adding an item, **When** I leave the price empty, **Then** the item is saved without a price and does not affect the total

---

### User Story 9 - Auto-Create Templates from Items (Priority: P3)

As a home member, I want the system to automatically create item templates when I add items so that future list creation is faster.

**Why this priority**: This is a passive feature that improves over time without requiring explicit user action.

**Independent Test**: Can be tested by adding an item and verifying a template is created (or usage count incremented) for that item name.

**Acceptance Scenarios**:

1. **Given** I add an item with a name that does not exist as a template, **When** the item is saved, **Then** a new template is created with the item's name, quantity, unit, and category
2. **Given** I add an item with a name that matches an existing template, **When** the item is saved, **Then** the template's usage count is incremented
3. **Given** a template exists, **When** I use it via Quick Add, **Then** the template's default values are used and usage count incremented

---

### Edge Cases

- What happens when a user tries to add an item to a list that has been deleted? → Show error message "List not found" and navigate back to lists screen
- How does the system handle conflicts when two users edit the same item simultaneously? → Last-write-wins: latest edit overwrites previous, no conflict UI shown
- What happens when a user is removed from a home while viewing a shopping list? → User is navigated back to the home screen with a message that they no longer have access
- How does the system handle very long item names? → Truncate display with ellipsis; allow up to 200 characters in the input field
- What happens when a user tries to add an item with a very large quantity? → Cap quantity at 9999; show validation error if exceeded
- How does the system handle network interruptions during item operations? → Basic offline: operations are queued locally and synced when connection is restored
- What happens when a category is deleted but items still reference it? → Items show "Uncategorized" until reassigned; no data loss
- What happens when a user adds an item with the same name as an existing item in the list? → System allows duplicates but shows a warning snackbar "Item already exists, add anyway?" before saving

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow home members to add items to shopping lists they have access to
- **FR-002**: System MUST require item name as mandatory; quantity, unit, category, price, and notes are optional
- **FR-003**: System MUST provide autocomplete suggestions when typing item names, based on templates and previously added items; each suggestion displays name, quantity, and unit
- **FR-004**: System MUST allow users to mark items as purchased/unpurchased with a single tap
- **FR-005**: System MUST display who purchased an item and when
- **FR-006**: System MUST allow users to edit all item attributes (name, quantity, unit, category, price, notes)
- **FR-007**: System MUST allow users to delete items with a confirmation prompt and undo option
- **FR-008**: System MUST provide search functionality within a shopping list by item name
- **FR-009**: System MUST provide category-based filtering within a shopping list
- **FR-010**: System MUST group items by category with collapsible headers; within each group, purchased items sink to the bottom
- **FR-011**: System MUST provide a Quick Add feature that shows frequently used item templates
- **FR-012**: System MUST auto-create or update item templates only when items are added to lists (not when edited)
- **FR-013**: System MUST allow users to optionally enter a price per item
- **FR-014**: System MUST display a running total of prices for unpurchased items only
- **FR-015**: System MUST synchronize all item changes in real-time across all home members viewing the list
- **FR-016**: System MUST use last-write-wins strategy for concurrent edits without conflict UI
- **FR-017**: System MUST enforce home membership — only members of the home can view or modify items
- **FR-018**: System MUST support Arabic and English languages with RTL layout for all item UI
- **FR-019**: System MUST handle offline scenarios by queuing operations locally and syncing when reconnected
- **FR-020**: System MUST cap item quantity at 9999 and item name at 200 characters
- **FR-021**: System MUST warn users when adding an item with a name that already exists in the list, allowing them to confirm or cancel

### Key Entities

- **Shopping Item**: Represents an individual item within a shopping list. Key attributes: name, quantity, unit, category (optional), price (optional), notes (optional), is_purchased, purchased_by, purchased_at, shopping_list_id, created_by, created_at, updated_at
- **Item Template**: Represents a frequently used item for quick addition. Key attributes: name, default_quantity, default_unit, category, usage_count, home_id, created_at

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can add an item to a shopping list in under 15 seconds
- **SC-002**: Users can mark an item as purchased with a single tap in under 2 seconds
- **SC-003**: Real-time updates appear on all devices within 2 seconds of a change
- **SC-004**: 95% of users can add, edit, and mark items as purchased on first attempt without guidance
- **SC-005**: The item list remains responsive and scrollable with up to 200 items per list
- **SC-006**: Autocomplete suggestions appear within 500 milliseconds of typing
- **SC-007**: 90% of users report that adding items is fast and intuitive
- **SC-008**: Quick Add from templates reduces item entry time by at least 50% for repeat items

## Assumptions

- Shopping lists already exist from SPEC 05; this feature operates on items within those lists
- Categories and units from SPEC 04 are available for item categorization
- The home membership and permission system from SPEC 02/03 is in place
- Real-time synchronization uses Supabase Realtime subscriptions
- Notifications for item changes are handled by a separate notification feature (not in scope)
- Item templates are home-scoped — each home has its own set of templates
- The UI follows the existing Beity design system with Arabic RTL support
- Offline support is basic: local view/edit with sync on reconnect; no conflict resolution UI

## Clarifications

### Session 2026-05-12

- Q: How should items be sorted by default? → A: Group by category with collapsible headers; purchased items sink to the bottom of each group
- Q: Should the system allow duplicate item names within the same list? → A: Allow duplicates but warn — show "Item already exists, add anyway?" before saving
- Q: Should editing an item also update the corresponding item template? → A: No — templates are only created/updated when items are added, not edited
- Q: What details should each autocomplete suggestion display? → A: Name + quantity + unit
- Q: Should the running price total include all items or only unpurchased items? → A: Only unpurchased items — shows the remaining cost to spend
