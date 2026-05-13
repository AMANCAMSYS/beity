# Data Model: Inventory Phase

**Feature**: 013-inventory-phase  
**Date**: 2026-05-13  
**Status**: Complete

## Entities

### 1. inventory_items

Represents a physical item tracked in a home's inventory.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| id | UUID | NO | gen_random_uuid() | Primary key |
| home_id | UUID | NO | - | Foreign key to homes table |
| name | VARCHAR(255) | NO | - | Item name |
| quantity | DECIMAL(10,2) | NO | 0 | Current quantity in stock |
| unit_id | UUID | YES | NULL | Foreign key to units table |
| category_id | UUID | YES | NULL | Foreign key to categories table |
| min_quantity | DECIMAL(10,2) | YES | NULL | Low-stock threshold (user-defined) |
| notes | TEXT | YES | NULL | Optional free-text notes (storage location, brand, etc.) |
| created_by | UUID | NO | - | Foreign key to auth.users |
| updated_by | UUID | NO | - | Foreign key to auth.users (last person to modify) |
| created_at | TIMESTAMP WITH TIME ZONE | NO | NOW() | Creation timestamp |
| updated_at | TIMESTAMP WITH TIME ZONE | NO | NOW() | Last update timestamp |
| deleted_at | TIMESTAMP WITH TIME ZONE | YES | NULL | Soft delete timestamp |

**Constraints**:
- PRIMARY KEY (id)
- FOREIGN KEY (home_id) REFERENCES homes(id) ON DELETE CASCADE
- FOREIGN KEY (unit_id) REFERENCES units(id)
- FOREIGN KEY (category_id) REFERENCES categories(id)
- FOREIGN KEY (created_by) REFERENCES auth.users(id)
- FOREIGN KEY (updated_by) REFERENCES auth.users(id)
- CHECK (quantity >= 0)
- CHECK (min_quantity IS NULL OR min_quantity >= 0)
- UNIQUE (home_id, name, unit_id, deleted_at) — Prevents duplicate items per home (excluding deleted)

**Indexes**:
- idx_inventory_items_home_id ON (home_id)
- idx_inventory_items_category ON (home_id, category_id)
- idx_inventory_items_name_search ON (home_id, name) — For auto-suggest queries
- idx_inventory_items_low_stock ON (home_id) WHERE quantity <= min_quantity AND deleted_at IS NULL — Partial index for low-stock queries
- idx_inventory_items_updated_by ON (updated_by)

**RLS Policies**:
```sql
-- Helper function: check home membership (reuses existing pattern)
-- Note: is_home_member function likely already exists from prior specs.
-- If not, create it following the same security definer pattern.

-- Users can only see inventory items for homes they are members of
CREATE POLICY "Users can view inventory items for their homes"
ON inventory_items FOR SELECT
USING (
  home_id IN (
    SELECT home_id FROM home_members
    WHERE user_id = (select auth.uid())
  )
);

-- Users can add inventory items to homes they are members of
CREATE POLICY "Users can add inventory items"
ON inventory_items FOR INSERT
WITH CHECK (
  home_id IN (
    SELECT home_id FROM home_members
    WHERE user_id = (select auth.uid())
  )
  AND created_by = (select auth.uid())
  AND updated_by = (select auth.uid())
);

-- Users can update inventory items in homes they are members of
CREATE POLICY "Users can update inventory items"
ON inventory_items FOR UPDATE
USING (
  home_id IN (
    SELECT home_id FROM home_members
    WHERE user_id = (select auth.uid())
  )
)
WITH CHECK (
  updated_by = (select auth.uid())
);

-- Users can delete inventory items in homes they are members of
CREATE POLICY "Users can delete inventory items"
ON inventory_items FOR DELETE
USING (
  home_id IN (
    SELECT home_id FROM home_members
    WHERE user_id = (select auth.uid())
  )
);
```

**Triggers**:
```sql
-- Auto-update updated_at on changes
CREATE TRIGGER set_updated_at
BEFORE UPDATE ON inventory_items
FOR EACH ROW
EXECUTE FUNCTION moddatetime(updated_at);
```

---

### 2. inventory_transactions

Records every quantity change for auditability and accountability.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| id | UUID | NO | gen_random_uuid() | Primary key |
| inventory_item_id | UUID | NO | - | Foreign key to inventory_items |
| home_id | UUID | NO | - | Foreign key to homes table (denormalized for RLS efficiency) |
| previous_quantity | DECIMAL(10,2) | NO | - | Quantity before the change |
| new_quantity | DECIMAL(10,2) | NO | - | Quantity after the change |
| change_reason | VARCHAR(50) | NO | - | Reason: 'manual_update', 'shopping_restock', 'zero_removal', 'initial_add', 'delete' |
| changed_by | UUID | NO | - | Foreign key to auth.users |
| created_at | TIMESTAMP WITH TIME ZONE | NO | NOW() | When the change occurred |

**Constraints**:
- PRIMARY KEY (id)
- FOREIGN KEY (inventory_item_id) REFERENCES inventory_items(id) ON DELETE CASCADE
- FOREIGN KEY (home_id) REFERENCES homes(id) ON DELETE CASCADE
- FOREIGN KEY (changed_by) REFERENCES auth.users(id)

**Indexes**:
- idx_inventory_transactions_item_id ON (inventory_item_id)
- idx_inventory_transactions_home_id ON (home_id)
- idx_inventory_transactions_created_at ON (inventory_item_id, created_at DESC) — For history queries

**RLS Policies**:
```sql
-- Users can view transactions for inventory items in their homes
CREATE POLICY "Users can view inventory transactions"
ON inventory_transactions FOR SELECT
USING (
  home_id IN (
    SELECT home_id FROM home_members
    WHERE user_id = (select auth.uid())
  )
);

-- Users can create transactions for items in their homes
CREATE POLICY "Users can create inventory transactions"
ON inventory_transactions FOR INSERT
WITH CHECK (
  home_id IN (
    SELECT home_id FROM home_members
    WHERE user_id = (select auth.uid())
  )
  AND changed_by = (select auth.uid())
);
```

**Note**: Transactions are append-only. No UPDATE or DELETE policies are needed. If an inventory item is deleted, its transactions are cascade-deleted.

---

## Entity Relationships

```
homes (1) ──── (N) inventory_items
  │                     │
  │                     ├── (N) ──── (1) units
  │                     │
  │                     ├── (N) ──── (1) categories
  │                     │
  │                     └── (1) ──── (N) inventory_transactions
  │
  └── (1) ──── (N) inventory_transactions (denormalized home_id for RLS)
```

## State Transitions

### Inventory Item Lifecycle

```
active ──────► deleted (soft delete via deleted_at)
  │                │
  │                │
  └────────────────┘ (restore by clearing deleted_at)
```

- **active**: Default state, item visible in inventory
- **deleted**: Soft-deleted via `deleted_at` timestamp, not visible to users

### Quantity State

```
positive ──────► zero ──────► removed (auto-removed when quantity hits 0)
```

- **positive**: Item has stock, visible in inventory
- **zero**: Triggers automatic removal from inventory (soft delete)
- **low-stock**: Transient state when quantity ≤ min_quantity (flagged in UI, not persisted as status)

## Data Volume Assumptions

- Up to 500 inventory items per home
- Up to 1000 transactions per item over its lifetime
- Average 5-10 quantity updates per item per week
- Up to 100 homes with active inventory

## Migration Strategy

1. Create `inventory_items` table
2. Create `inventory_transactions` table
3. Enable RLS on both tables
4. Create all indexes (including partial index for low-stock)
5. Create triggers for `updated_at`
6. Seed: no seed data needed (inventory is user-populated)
