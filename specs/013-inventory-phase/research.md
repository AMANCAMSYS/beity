# Research: Inventory Phase

**Feature**: 013-inventory-phase  
**Date**: 2026-05-13  
**Status**: Complete

## Research Tasks

### 1. Inventory Transaction Log Pattern

**Decision**: Implement a separate `inventory_transactions` table that records every quantity change as an append-only log.

**Rationale**: The spec requires full accountability (who changed what, when, by how much). A separate transaction table avoids bloating the main inventory table and allows efficient history queries. This mirrors audit log patterns used in inventory management systems.

**Alternatives considered**:
- **Single table with history columns**: Store only `last_changed_by` and `last_changed_at` on the inventory item. Rejected: loses full history, cannot answer "what was the quantity last week?"
- **Postgres temporal tables (system-time versioning)**: Use `GENERATED ALWAYS AS ROW START/END`. Rejected: adds complexity, Supabase doesn't expose this well via the client SDK, and we need explicit `change_reason` metadata.
- **Trigger-based audit table**: Use a Postgres trigger to auto-log changes. Considered viable but decided to handle in application layer for consistency with existing patterns (shopping_items uses app-level purchased_by/purchased_at tracking).

### 2. Low-Stock Threshold and Restock Suggestion

**Decision**: Add `min_quantity` (DECIMAL(10,2)) column to `inventory_items`. When quantity ≤ min_quantity, item is flagged as low-stock. Restock suggestion = (min_quantity × 2) − current quantity.

**Rationale**: User-defined thresholds per item allow flexibility (a family may want to always have at least 2L of milk but only 1 bottle of olive oil). The ×2 formula provides a simple, predictable restock target without requiring users to set a separate "desired quantity" field.

**Alternatives considered**:
- **Global threshold setting**: One number for all items. Rejected: too rigid — different items have different consumption rates.
- **No threshold, use historical average**: Calculate suggestion from purchase history. Rejected: requires sufficient purchase data (cold start problem), more complex to implement, and the spec explicitly chose user-defined thresholds.
- **Separate "desired quantity" field**: User sets both min and target. Rejected: adds cognitive overhead for marginal benefit over the ×2 formula.

### 3. Fractional Quick-Adjust Step

**Decision**: Quick-adjust step is determined by the item's unit type. Units with `is_fractional = true` (kg, liters, etc.) use ±0.5 step; all others use ±1.

**Rationale**: This matches the clarification answer and provides intuitive behavior — users buying rice by the kilogram don't want to adjust by 1g increments, and users buying eggs don't want 0.5 egg steps. The unit's fractional flag is already determinable from the existing `units` table (SPEC 004).

**Alternatives considered**:
- **Always ±1**: Simple but frustrating for fractional units (tapping 10 times for 5kg).
- **User-configurable step per item**: Most flexible but adds setup overhead and UI complexity for a feature that's meant to be fast.
- **Smart step based on current quantity**: E.g., step increases as quantity grows. Rejected: unpredictable behavior confuses users.

### 4. Duplicate Detection for Inventory Items

**Decision**: Duplicate detection uses case-insensitive name match + same unit_id within a home. Adding a duplicate increases the existing item's quantity.

**Rationale**: This matches the existing `item_templates` pattern (UNIQUE on home_id + name). Case-insensitive matching prevents "Milk" and "milk" from being separate items. Unit-aware matching ensures "2 kg rice" and "500g rice" are treated as different stock entries.

**Alternatives considered**:
- **Name-only matching**: Rejected — "500g flour" and "1kg flour" are genuinely different stock entries.
- **Fuzzy matching (Levenshtein distance)**: Rejected — over-engineering for inventory; exact match with normalization is sufficient.
- **No duplicate detection**: Rejected — leads to inventory bloat and defeats the purpose of consolidated stock tracking.

### 5. Shopping List Integration Pattern

**Decision**: The "Add to Shopping List" action creates a `shopping_items` entry (or updates existing) in the selected list. The "Add to Inventory" toggle on purchased shopping items triggers an upsert into `inventory_items` after purchase.

**Rationale**: Both directions reuse existing Supabase operations and the established shopping list data model. No new tables or foreign keys needed between inventory and shopping_items — the integration is at the use-case level, not the data level.

**Alternatives considered**:
- **Foreign key from shopping_items to inventory_items**: Rejected: creates tight coupling; an item can be on a shopping list without being in inventory and vice versa.
- **Shared "products" table**: Rejected: out of scope (no barcode/product catalog in this phase).
- **Separate "restock_requests" table**: Rejected: unnecessary indirection; the shopping list itself serves as the restock request.

### 6. Realtime Sync for Inventory

**Decision**: Use Supabase Realtime (stream on `inventory_items` filtered by `home_id`) following the same pattern as `shopping_items`.

**Rationale**: Consistent with existing architecture. Supabase Realtime handles INSERT/UPDATE/DELETE broadcasts automatically when RLS policies allow SELECT. The existing `shopping_items` feature proves this pattern works at the target scale.

**Alternatives considered**:
- **Polling**: Rejected: higher latency, more server load, worse UX.
- **Custom WebSocket solution**: Rejected: Supabase Realtime already solves this.
- **Optimistic updates only (no sync)**: Rejected: other household members need to see changes immediately.

### 7. Offline Queue Integration

**Decision**: Inventory mutations (add, update, delete) are queued in the existing `offline_queue` table when offline and replayed when connectivity returns.

**Rationale**: The project already has an offline queue mechanism (SPEC 011). Inventory operations are structurally similar to shopping item operations and can use the same queue infrastructure without new abstractions.

**Alternatives considered**:
- **Separate offline storage for inventory**: Rejected: duplicates existing infrastructure.
- **No offline support for inventory**: Rejected: violates the offline-capable constraint in AGENTS.md.
