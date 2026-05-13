# Feature Specification: Inventory Phase

**Feature Branch**: `013-inventory-phase`  
**Created**: 2026-05-13  
**Status**: Draft  
**Input**: User description: "SPEC 13 — Inventory Phase"

## Clarifications

### Session 2026-05-13

- Q: Should the system track every quantity change (audit log) or only store the current quantity? → A: Full transaction log — every change recorded with user, timestamp, previous/new value. Enables history and accountability.
- Q: How should low-stock items be identified and what quantity should be suggested for restocking? → A: User-defined threshold per item — user sets a "minimum quantity" field; when stock drops below it, item is flagged as low. Suggested restock = (threshold × 2) − current quantity.
- Q: For items measured in fractional units (kg, liters), should quick-adjust buttons change by fractional amounts? → A: ±1 per unit type — whole units (pieces, packs) adjust by 1; fractional units (kg, liters) adjust by 0.5.
- Q: Should inventory items support notes for context like storage location or brand? → A: Include notes field — optional free-text field on each inventory item. Useful for storage location or brand notes.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - View Home Inventory (Priority: P1)

As a home member, I want to see all items currently in my home inventory so that I know what we have on hand without checking shelves.

**Why this priority**: The inventory list is the foundation of the entire feature. Without viewing inventory, no other inventory functionality delivers value.

**Independent Test**: Can be fully tested by opening the inventory screen and verifying that all inventory items appear with their name, quantity, unit, and category.

**Acceptance Scenarios**:

1. **Given** I am a member of a home with inventory items, **When** I open the inventory screen, **Then** I see all items grouped by category with current quantity and unit
2. **Given** the inventory is empty, **When** I open the inventory screen, **Then** I see an empty state explaining how to add items
3. **Given** I am viewing inventory, **When** items exist in multiple categories, **Then** items are grouped by category with category headers

---

### User Story 2 - Add Item to Inventory (Priority: P1)

As a home member, I want to add an item to my home inventory so that I can track what we have purchased and brought home.

**Why this priority**: Adding items is the primary way to populate the inventory and must work quickly to be useful during unpacking.

**Independent Test**: Can be tested by adding an item with name, quantity, unit, and category and verifying it appears in the inventory list.

**Acceptance Scenarios**:

1. **Given** I am viewing the inventory screen, **When** I tap "Add Item" and enter a name, quantity, and unit, **Then** the item appears in the inventory under the selected category
2. **Given** I am adding an inventory item, **When** I type the item name, **Then** I see suggestions from existing item templates and previously used items
3. **Given** I am adding an item that already exists in inventory, **When** I confirm the addition, **Then** the system increases the existing item's quantity rather than creating a duplicate
4. **Given** I am adding an item, **When** I leave the category unselected, **Then** the item is saved under "Uncategorized"

---

### User Story 3 - Update Inventory Quantity (Priority: P1)

As a home member, I want to update the quantity of an inventory item so that the inventory stays accurate as items are consumed or restocked.

**Why this priority**: Quantity tracking is the core value of an inventory — without updates, the data becomes stale and useless.

**Independent Test**: Can be tested by changing an item's quantity and verifying the new quantity persists and is visible to all home members.

**Acceptance Scenarios**:

1. **Given** I am viewing an inventory item, **When** I tap to edit the quantity and enter a new value, **Then** the quantity updates and is visible to all home members
2. **Given** I reduce an item's quantity to zero, **When** I confirm the update, **Then** the item is removed from inventory automatically
3. **Given** I am viewing inventory, **When** I use quick-adjust controls (plus/minus buttons), **Then** the quantity changes by 1 for whole-unit items (pieces, packs) or 0.5 for fractional-unit items (kg, liters)
4. **Given** multiple members are viewing inventory, **When** one member updates a quantity, **Then** all other members see the change in real-time

---

### User Story 4 - Remove Item from Inventory (Priority: P2)

As a home member, I want to remove an item from inventory when it is fully consumed or no longer needed so that the inventory stays relevant.

**Why this priority**: Removal keeps the inventory clean but is less frequent than quantity updates.

**Independent Test**: Can be tested by deleting an item and verifying it no longer appears in the inventory list.

**Acceptance Scenarios**:

1. **Given** I am viewing an inventory item, **When** I choose to delete it, **Then** I am asked to confirm before the item is removed
2. **Given** an item is deleted, **When** I view the inventory, **Then** the item no longer appears in any category group

---

### User Story 5 - Add Inventory Item to Shopping List (Priority: P2)

As a home member, I want to add a low-stock or missing inventory item directly to a shopping list so that I can easily restock.

**Why this priority**: This bridges the inventory and shopping list features, creating a seamless restocking workflow.

**Independent Test**: Can be tested by selecting an inventory item, choosing "Add to Shopping List," and verifying the item appears in the selected list.

**Acceptance Scenarios**:

1. **Given** I am viewing an inventory item at or below its minimum quantity threshold, **When** I tap "Add to Shopping List" and select a list, **Then** the item is added to that shopping list with suggested quantity = (threshold × 2) − current quantity
2. **Given** the item already exists in the selected shopping list, **When** I add it from inventory, **Then** the system updates the existing shopping list item's quantity instead of creating a duplicate
3. **Given** I have no shopping lists, **When** I try to add an item to a list, **Then** I am prompted to create a new shopping list first

---

### User Story 6 - Mark Shopping Item as "Add to Inventory" (Priority: P3)

As a home member, when I mark a shopping item as purchased, I want the option to also add it to my home inventory so that newly bought items are automatically tracked.

**Why this priority**: This automation reduces manual data entry after shopping trips but is a convenience enhancement.

**Independent Test**: Can be tested by marking a shopping item as purchased with the "Add to Inventory" option enabled and verifying a new inventory entry is created.

**Acceptance Scenarios**:

1. **Given** I mark a shopping item as purchased, **When** the "Add to Inventory" toggle is on, **Then** the item is added to home inventory with the purchased quantity
2. **Given** the purchased item already exists in inventory, **When** the "Add to Inventory" option is used, **Then** the existing inventory item's quantity is increased by the purchased amount
3. **Given** I mark a shopping item as purchased, **When** the "Add to Inventory" toggle is off, **Then** no inventory change occurs

---

### Edge Cases

- What happens when two members update the same inventory item's quantity simultaneously? Last-write-wins with real-time sync to all members.
- How does the system handle inventory items whose category or unit is deleted? The item remains with a "None" label for the removed category/unit.
- What happens when a home is deleted? All inventory data for that home is cascade-deleted.
- How does the system handle extremely large inventories (500+ items)? Inventory screen uses lazy loading and category grouping to maintain performance.
- What happens if a user tries to add an item with negative quantity? The system rejects the input and shows a validation error.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow home members to view all inventory items for their home, grouped by category
- **FR-002**: System MUST allow home members to add new items to inventory with name, quantity, unit, and optional category
- **FR-003**: System MUST auto-suggest existing item names from templates and previous inventory entries when adding items
- **FR-004**: System MUST merge duplicates: adding an item that already exists (same name + unit) increases the existing item's quantity
- **FR-005**: System MUST allow home members to update the quantity of any inventory item in their home
- **FR-006**: System MUST provide quick-adjust controls (plus/minus) that change quantity by 1 for whole-unit items and 0.5 for fractional-unit items (kg, liters)
- **FR-007**: System MUST automatically remove items from inventory when quantity reaches zero
- **FR-008**: System MUST allow home members to manually delete inventory items with a confirmation step
- **FR-009**: System MUST allow home members to add any inventory item to a selected shopping list
- **FR-010**: System MUST detect if an item already exists in the target shopping list and update its quantity instead of creating a duplicate
- **FR-011**: System MUST provide an "Add to Inventory" option when marking shopping items as purchased
- **FR-012**: System MUST sync inventory changes to all home members in real-time
- **FR-013**: System MUST enforce home membership: only members of a home can view or modify that home's inventory
- **FR-014**: System MUST track who created and last updated each inventory item
- **FR-015**: System MUST support Arabic (RTL) and English (LTR) layouts for all inventory screens
- **FR-016**: System MUST display an informative empty state when no inventory items exist
- **FR-017**: System MUST allow users to set a minimum quantity threshold per inventory item
- **FR-018**: System MUST flag items as "low stock" when their quantity is at or below the user-defined threshold
- **FR-019**: System MUST record every inventory quantity change as a transaction entry with user, timestamp, previous value, new value, and change reason
- **FR-020**: System MUST allow users to optionally add notes (free-text) to each inventory item

### Key Entities

- **Inventory Item**: Represents a physical item in the home. Key attributes: name, quantity, unit, category, minimum quantity threshold, optional notes, home reference, created/updated metadata.
- **Inventory Transaction**: Represents a change to inventory quantity. Key attributes: item reference, previous quantity, new quantity, change reason (manual update, shopping restock, zero removal), changed by user, timestamp.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can add a new inventory item in under 15 seconds using auto-suggest and quick controls
- **SC-002**: Users can update an item's quantity in under 5 seconds using quick-adjust buttons
- **SC-003**: 90% of users can view and understand their inventory within 5 seconds of opening the inventory screen
- **SC-004**: Inventory changes sync to all home members within 2 seconds of the update
- **SC-005**: The "Add to Shopping List" flow completes in under 10 seconds from item selection to list addition
- **SC-006**: Zero data loss for inventory updates — every quantity change is persisted before confirming to the user
- **SC-007**: Inventory screens render smoothly (60fps) with up to 500 items across all categories

## Assumptions

- A home has one shared inventory (not per-member). All members see and edit the same inventory.
- Inventory items are generic (name + quantity + unit), not tied to specific products or barcodes.
- The "Add to Inventory" option on purchased shopping items is opt-in per item, not a global default.
- Inventory is scoped to a single home. Multi-home inventory aggregation is out of scope.
- Offline support follows the existing offline queue pattern — changes are queued and synced when connectivity returns.
- Item templates (SPEC 004) and categories (SPEC 004) are reused for inventory item suggestions and grouping.
- No price tracking or cost management in this phase — inventory is quantity-only.
- No barcode scanning or OCR in this phase — manual entry only.
