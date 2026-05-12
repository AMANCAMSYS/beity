# Feature Specification: Categories and Units

**Feature Branch**: `004-categories-and-units`  
**Created**: 2026-05-12  
**Status**: Draft  
**Input**: User description: "SPEC 04 — Categories and Units"

## User Scenarios & Testing

### User Story 1 - View Categories (Priority: P1)

As a user, I want to view available categories when creating or editing products, so that I can organize my shopping items logically.

**Why this priority**: Categories are essential for organizing products and must be available before product creation.

**Independent Test**: Can be tested by viewing the categories list and verifying all default categories appear.

**Acceptance Scenarios**:

1. **Given** I am a home member, **When** I view categories, **Then** I see all default categories and any custom categories for my home
2. **Given** I am viewing categories, **When** I select a category, **Then** it is highlighted and can be assigned to a product
3. **Given** there are no custom categories, **When** I view categories, **Then** I still see the default categories

---

### User Story 2 - Create Custom Categories (Priority: P2)

As a home owner/admin, I want to create custom categories for my home, so that I can organize products in a way that fits my household's needs.

**Why this priority**: Custom categories allow homes to personalize their organization system.

**Independent Test**: Can be tested by creating a custom category and verifying it appears in the categories list.

**Acceptance Scenarios**:

1. **Given** I am a home owner/admin, **When** I create a new category with name, icon, and color, **Then** the category is saved and visible to all home members
2. **Given** I try to create a category with a name that already exists, **When** I submit the form, **Then** I see an error message indicating the name is taken
3. **Given** I am a viewer, **When** I try to create a category, **Then** I see an error indicating I don't have permission

---

### User Story 3 - Edit and Delete Custom Categories (Priority: P2)

As a home owner/admin, I want to edit or delete custom categories, so that I can maintain the organization system as needs change.

**Why this priority**: Category management is important for long-term maintenance.

**Independent Test**: Can be tested by editing a category name and verifying the change persists.

**Acceptance Scenarios**:

1. **Given** I am a home owner/admin, **When** I edit a custom category, **Then** the changes are saved and visible to all home members
2. **Given** I try to edit a default category, **When** I attempt to save, **Then** I see an error indicating default categories cannot be modified
3. **Given** I am a home owner/admin, **When** I delete a custom category with no products, **Then** the category is removed
4. **Given** I try to delete a category that has products, **When** I attempt to delete, **Then** I see a warning that products will be uncategorized

---

### User Story 4 - View Units (Priority: P1)

As a user, I want to view available units when creating or editing products, so that I can specify quantities correctly.

**Why this priority**: Units are essential for specifying product quantities.

**Independent Test**: Can be tested by viewing the units list and verifying all default units appear.

**Acceptance Scenarios**:

1. **Given** I am a home member, **When** I view units, **Then** I see all default units and any custom units for my home
2. **Given** I am viewing units, **When** I select a unit, **Then** it is highlighted and can be assigned to a product
3. **Given** there are no custom units, **When** I view units, **Then** I still see the default units

---

### User Story 5 - Create Custom Units (Priority: P3)

As a home owner/admin, I want to create custom units for my home, so that I can measure products in ways specific to my household.

**Why this priority**: Custom units are less common but useful for specific needs.

**Independent Test**: Can be tested by creating a custom unit and verifying it appears in the units list.

**Acceptance Scenarios**:

1. **Given** I am a home owner/admin, **When** I create a new unit with name and symbol, **Then** the unit is saved and visible to all home members
2. **Given** I try to create a unit with a name that already exists, **When** I submit the form, **Then** I see an error message indicating the name is taken
3. **Given** I am a viewer, **When** I try to create a unit, **Then** I see an error indicating I don't have permission

---

### Edge Cases

- What happens when a product is assigned to a category that gets deleted?
- How does the system handle concurrent category edits by multiple admins?
- What happens when a unit is deleted that is used by products?
- How does the system handle category/unit names in different languages?

## Requirements

### Functional Requirements

- **FR-001**: System MUST display all default categories to all users
- **FR-002**: System MUST allow home owners/admins to create custom categories
- **FR-003**: System MUST prevent duplicate category names within a home
- **FR-004**: System MUST allow home owners/admins to edit custom categories
- **FR-005**: System MUST prevent editing of default categories
- **FR-006**: System MUST allow home owners/admins to delete custom categories
- **FR-007**: System MUST warn when deleting a category that has products
- **FR-008**: System MUST display all default units to all users
- **FR-009**: System MUST allow home owners/admins to create custom units
- **FR-010**: System MUST prevent duplicate unit names within a home
- **FR-011**: System MUST allow home owners/admins to edit custom units
- **FR-012**: System MUST prevent editing of default units
- **FR-013**: System MUST allow home owners/admins to delete custom units
- **FR-014**: System MUST organize categories by type (shopping, inventory, expense)
- **FR-015**: System MUST organize units by type (weight, volume, count, length)

### Key Entities

- **Category**: Represents a product category. Key attributes: home_id, name, type (shopping/inventory/expense), icon, color, sort_order, is_default
- **Unit**: Represents a measurement unit. Key attributes: name, symbol, type (weight/volume/count/length), is_default

## Success Criteria

### Measurable Outcomes

- **SC-001**: Users can view categories in under 1 second
- **SC-002**: Users can create a custom category in under 30 seconds
- **SC-003**: Users can view units in under 1 second
- **SC-004**: Users can create a custom unit in under 30 seconds
- **SC-005**: 100% of default categories and units are available to all users
- **SC-006**: Zero data loss when categories/units are modified

## Assumptions

- Default categories and units are pre-populated in the database
- Each home can have its own custom categories and units
- Default categories/units cannot be modified or deleted
- Categories are organized by type (shopping, inventory, expense)
- Units are organized by type (weight, volume, count, length)
- Arabic and English names are supported for categories and units
