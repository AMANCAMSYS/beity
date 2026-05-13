# Data Model: Shopping Lists

**Feature**: 005-shopping-lists  
**Date**: 2026-05-12  
**Status**: Complete

## Entities

### 1. shopping_lists

Represents a collection of items to be purchased for a home.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| id | UUID | NO | gen_random_uuid() | Primary key |
| home_id | UUID | NO | - | Foreign key to homes table |
| name | VARCHAR(255) | NO | - | List name |
| description | TEXT | YES | NULL | Optional description |
| created_by | UUID | NO | - | Foreign key to auth.users |
| status | VARCHAR(20) | NO | 'active' | List status (active/archived) |
| created_at | TIMESTAMP WITH TIME ZONE | NO | NOW() | Creation timestamp |
| updated_at | TIMESTAMP WITH TIME ZONE | NO | NOW() | Last update timestamp |
| deleted_at | TIMESTAMP WITH TIME ZONE | YES | NULL | Soft delete timestamp |

**Constraints**:
- PRIMARY KEY (id)
- FOREIGN KEY (home_id) REFERENCES homes(id) ON DELETE CASCADE
- FOREIGN KEY (created_by) REFERENCES auth.users(id)
- UNIQUE (home_id, name, deleted_at) - Prevents duplicate names per home (excluding deleted)

**Indexes**:
- idx_shopping_lists_home_id ON (home_id)
- idx_shopping_lists_status ON (home_id, status)
- idx_shopping_lists_created_by ON (created_by)

**RLS Policies**:
```sql
-- Users can only see lists for homes they are members of
CREATE POLICY "Users can view shopping lists for their homes"
ON shopping_lists FOR SELECT
USING (
  home_id IN (
    SELECT home_id FROM home_members 
    WHERE user_id = auth.uid()
  )
);

-- Users can create lists in homes they are members of
CREATE POLICY "Users can create shopping lists"
ON shopping_lists FOR INSERT
WITH CHECK (
  home_id IN (
    SELECT home_id FROM home_members 
    WHERE user_id = auth.uid()
  )
  AND created_by = auth.uid()
);

-- Users can update lists they created or if they are home owner/admin
CREATE POLICY "Users can update shopping lists"
ON shopping_lists FOR UPDATE
USING (
  created_by = auth.uid()
  OR home_id IN (
    SELECT home_id FROM home_members 
    WHERE user_id = auth.uid() 
    AND role IN ('owner', 'admin')
  )
);

-- Users can delete lists they created or if they are home owner/admin
CREATE POLICY "Users can delete shopping lists"
ON shopping_lists FOR DELETE
USING (
  created_by = auth.uid()
  OR home_id IN (
    SELECT home_id FROM home_members 
    WHERE user_id = auth.uid() 
    AND role IN ('owner', 'admin')
  )
);
```

**Triggers**:
```sql
-- Auto-update updated_at on changes
CREATE TRIGGER set_updated_at
BEFORE UPDATE ON shopping_lists
FOR EACH ROW
EXECUTE FUNCTION moddatetime(updated_at);
```

---

### 2. shopping_items

Represents an individual item in a shopping list.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| id | UUID | NO | gen_random_uuid() | Primary key |
| shopping_list_id | UUID | NO | - | Foreign key to shopping_lists |
| name | VARCHAR(255) | NO | - | Item name |
| quantity | DECIMAL(10,2) | NO | 1 | Item quantity |
| unit_id | UUID | YES | NULL | Foreign key to units table |
| category_id | UUID | YES | NULL | Foreign key to categories table |
| price | DECIMAL(10,2) | YES | NULL | Optional price |
| currency | VARCHAR(3) | YES | 'SAR' | Currency code (default SAR) |
| notes | TEXT | YES | NULL | Optional notes |
| is_purchased | BOOLEAN | NO | FALSE | Purchase status |
| purchased_by | UUID | YES | NULL | Foreign key to auth.users |
| purchased_at | TIMESTAMP WITH TIME ZONE | YES | NULL | Purchase timestamp |
| created_by | UUID | NO | - | Foreign key to auth.users |
| created_at | TIMESTAMP WITH TIME ZONE | NO | NOW() | Creation timestamp |
| updated_at | TIMESTAMP WITH TIME ZONE | NO | NOW() | Last update timestamp |

**Constraints**:
- PRIMARY KEY (id)
- FOREIGN KEY (shopping_list_id) REFERENCES shopping_lists(id) ON DELETE CASCADE
- FOREIGN KEY (unit_id) REFERENCES units(id)
- FOREIGN KEY (category_id) REFERENCES categories(id)
- FOREIGN KEY (purchased_by) REFERENCES auth.users(id)
- FOREIGN KEY (created_by) REFERENCES auth.users(id)
- CHECK (quantity > 0)
- CHECK (price IS NULL OR price >= 0)

**Indexes**:
- idx_shopping_items_list_id ON (shopping_list_id)
- idx_shopping_items_purchased ON (shopping_list_id, is_purchased)
- idx_shopping_items_category ON (category_id)
- idx_shopping_items_name ON (shopping_list_id, name)

**RLS Policies**:
```sql
-- Users can only see items for lists in homes they are members of
CREATE POLICY "Users can view shopping items"
ON shopping_items FOR SELECT
USING (
  shopping_list_id IN (
    SELECT sl.id FROM shopping_lists sl
    JOIN home_members hm ON sl.home_id = hm.home_id
    WHERE hm.user_id = auth.uid()
  )
);

-- Users can add items to lists in homes they are members of
CREATE POLICY "Users can add shopping items"
ON shopping_items FOR INSERT
WITH CHECK (
  shopping_list_id IN (
    SELECT sl.id FROM shopping_lists sl
    JOIN home_members hm ON sl.home_id = hm.home_id
    WHERE hm.user_id = auth.uid()
  )
  AND created_by = auth.uid()
);

-- Users can update items in lists for homes they are members of
CREATE POLICY "Users can update shopping items"
ON shopping_items FOR UPDATE
USING (
  shopping_list_id IN (
    SELECT sl.id FROM shopping_lists sl
    JOIN home_members hm ON sl.home_id = hm.home_id
    WHERE hm.user_id = auth.uid()
  )
);

-- Users can delete items from lists for homes they are members of
CREATE POLICY "Users can delete shopping items"
ON shopping_items FOR DELETE
USING (
  shopping_list_id IN (
    SELECT sl.id FROM shopping_lists sl
    JOIN home_members hm ON sl.home_id = hm.home_id
    WHERE hm.user_id = auth.uid()
  )
);
```

**Triggers**:
```sql
-- Auto-update updated_at on changes
CREATE TRIGGER set_updated_at
BEFORE UPDATE ON shopping_items
FOR EACH ROW
EXECUTE FUNCTION moddatetime(updated_at);

-- Update purchased_by and purchased_at when is_purchased changes
CREATE TRIGGER set_purchased_info
BEFORE UPDATE ON shopping_items
FOR EACH ROW
WHEN (OLD.is_purchased IS DISTINCT FROM NEW.is_purchased)
EXECUTE FUNCTION update_purchased_info();
```

---

### 3. item_templates

Represents frequently used items for quick addition.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| id | UUID | NO | gen_random_uuid() | Primary key |
| home_id | UUID | NO | - | Foreign key to homes table |
| name | VARCHAR(255) | NO | - | Template name |
| default_quantity | DECIMAL(10,2) | NO | 1 | Default quantity |
| default_unit_id | UUID | YES | NULL | Foreign key to units table |
| default_category_id | UUID | YES | NULL | Foreign key to categories table |
| usage_count | INTEGER | NO | 0 | Times used |
| created_by | UUID | NO | - | Foreign key to auth.users |
| created_at | TIMESTAMP WITH TIME ZONE | NO | NOW() | Creation timestamp |
| updated_at | TIMESTAMP WITH TIME ZONE | NO | NOW() | Last update timestamp |

**Constraints**:
- PRIMARY KEY (id)
- FOREIGN KEY (home_id) REFERENCES homes(id) ON DELETE CASCADE
- FOREIGN KEY (default_unit_id) REFERENCES units(id)
- FOREIGN KEY (default_category_id) REFERENCES categories(id)
- FOREIGN KEY (created_by) REFERENCES auth.users(id)
- UNIQUE (home_id, name) - One template per name per home

**Indexes**:
- idx_item_templates_home_id ON (home_id)
- idx_item_templates_usage ON (home_id, usage_count DESC)

**RLS Policies**:
```sql
-- Users can only see templates for homes they are members of
CREATE POLICY "Users can view item templates"
ON item_templates FOR SELECT
USING (
  home_id IN (
    SELECT home_id FROM home_members 
    WHERE user_id = auth.uid()
  )
);

-- Users can create templates in homes they are members of
CREATE POLICY "Users can create item templates"
ON item_templates FOR INSERT
WITH CHECK (
  home_id IN (
    SELECT home_id FROM home_members 
    WHERE user_id = auth.uid()
  )
  AND created_by = auth.uid()
);

-- Users can update templates in homes they are members of
CREATE POLICY "Users can update item templates"
ON item_templates FOR UPDATE
USING (
  home_id IN (
    SELECT home_id FROM home_members 
    WHERE user_id = auth.uid()
  )
);

-- Users can delete templates in homes they are members of
CREATE POLICY "Users can delete item templates"
ON item_templates FOR DELETE
USING (
  home_id IN (
    SELECT home_id FROM home_members 
    WHERE user_id = auth.uid()
  )
);
```

**Triggers**:
```sql
-- Auto-update updated_at on changes
CREATE TRIGGER set_updated_at
BEFORE UPDATE ON item_templates
FOR EACH ROW
EXECUTE FUNCTION moddatetime(updated_at);
```

---

## Entity Relationships

```
homes (1) ──── (N) shopping_lists
  │                     │
  │                     │
  │                     └── (1) ──── (N) shopping_items
  │                                      │
  │                                      ├── (N) ──── (1) units
  │                                      │
  │                                      └── (N) ──── (1) categories
  │
  └── (1) ──── (N) item_templates
                    │
                    ├── (N) ──── (1) units
                    │
                    └── (N) ──── (1) categories
```

## State Transitions

### Shopping List Status
```
active ──────► archived
  │               │
  │               │
  └───────────────┘ (restore)
```

- **active**: Default state, list is visible and editable
- **archived**: List is hidden from main view, can be restored
- **deleted**: Soft-deleted via deleted_at timestamp, not visible

### Shopping Item Purchase State
```
unpurchased ◄───► purchased
```

- **unpurchased**: Default state, item needs to be bought
- **purchased**: Item has been bought, tracked by purchased_by and purchased_at

## Data Volume Assumptions

- Up to 50 shopping lists per home
- Up to 200 items per shopping list
- Up to 100 item templates per home
- Average 10 items purchased per list per week

## Migration Strategy

1. Create tables in order: shopping_lists → shopping_items → item_templates
2. Enable RLS on all tables
3. Create indexes for performance
4. Add triggers for updated_at and purchased info
5. Seed default item templates from common groceries
