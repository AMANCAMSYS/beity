# Research: Shopping Items

**Feature**: 006-shopping-items  
**Date**: 2026-05-12  
**Status**: Complete

## Decision 1: Enhance Existing vs. New Feature Directory

**Decision**: Enhance the existing `lib/features/shopping_lists/` directory from SPEC 05 rather than creating a new feature directory.

**Rationale**: 
- SPEC 05 already created all data models (`shopping_item_model.dart`, `item_template_model.dart`), entities, repositories, and basic use cases
- The Supabase tables (`shopping_items`, `item_templates`) are already created with RLS policies
- Shopping items are logically part of the shopping lists feature — separating them would create unnecessary coupling
- The existing codebase already has providers, screens, and widgets that need enhancement

**Alternatives considered**:
- New `lib/features/shopping_items/` directory: Rejected because it would duplicate repository connections and create circular dependencies with shopping_lists
- Separate `lib/features/item_templates/` directory: Rejected because templates are tightly coupled to the item add flow

---

## Decision 2: Category Grouping Strategy

**Decision**: Implement category grouping at the presentation layer using a grouped `ListView` with collapsible headers. Purchased items sink to the bottom of each category group.

**Rationale**:
- Category grouping is a UI concern, not a data concern — items remain flat in the database
- The existing `category_id` foreign key on `shopping_items` provides the grouping key
- Collapsible headers improve UX for long lists (200+ items)
- Sinking purchased items to bottom within each group keeps the shopping flow intuitive

**Alternatives considered**:
- Server-side sorting with category order column: Rejected — adds complexity without benefit since grouping is purely presentational
- Separate "purchased" section at list bottom: Rejected — breaks category-based shopping flow

---

## Decision 3: Autocomplete Implementation

**Decision**: Implement autocomplete using a local search against item templates and previously added items. Each suggestion shows name, quantity, and unit.

**Rationale**:
- Templates are already stored in `item_templates` table with home_id scope
- Previously added items can be queried from `shopping_items` with deduplication by name
- Local search is fast (<500ms) and works offline
- Showing name + quantity + unit gives enough context without overwhelming the dropdown

**Alternatives considered**:
- Server-side full-text search: Rejected — overkill for per-list autocomplete, adds latency
- Fuzzy matching library: Rejected — simple `ILIKE` prefix matching is sufficient for MVP

---

## Decision 4: Duplicate Item Warning Flow

**Decision**: Allow duplicate item names but show a warning snackbar "Item already exists, add anyway?" before saving. User can confirm or cancel.

**Rationale**:
- Real-world shopping often requires the same item from different sources (e.g., "milk" from two brands)
- Warning is non-blocking — users can still add duplicates if intentional
- Simple client-side check against current list items — no server round-trip needed

**Alternatives considered**:
- Block duplicates entirely: Rejected — too restrictive for real use cases
- Auto-merge quantities: Rejected — surprising behavior, users should explicitly choose

---

## Decision 5: Template Auto-Create Behavior

**Decision**: Templates are only created/updated when items are added to lists, NOT when items are edited.

**Rationale**:
- Templates represent the "canonical" version of frequently bought items
- Editing an item (e.g., fixing a typo) should not pollute the template
- Keeps template data clean and predictable
- Usage count incremented only on add, not edit

**Alternatives considered**:
- Update templates on edit: Rejected — typo corrections would overwrite good template data
- Prompt user to update template on edit: Rejected — adds friction to a simple edit flow

---

## Decision 6: Price Total Calculation

**Decision**: Running price total includes only unpurchased items.

**Rationale**:
- Users want to know "what am I about to spend?" not "what have I already spent?"
- Purchased items are already bought — their cost is sunk
- Simpler calculation and more actionable information

**Alternatives considered**:
- Show both totals (remaining + budget): Deferred to post-MVP — adds UI complexity
- Include all items: Rejected — less useful for shopping decision-making

---

## Decision 7: Offline Strategy

**Decision**: Basic offline support — view and edit items locally, queue operations, auto-sync when reconnected.

**Rationale**:
- Aligns with SPEC 05's offline strategy
- Supabase Realtime handles sync when online
- Local state in Riverpod providers serves as the "offline view"
- No conflict resolution UI — last-write-wins

**Alternatives considered**:
- Isar local database: Deferred to post-MVP — adds complexity
- Full conflict resolution: Rejected — over-engineering for MVP
