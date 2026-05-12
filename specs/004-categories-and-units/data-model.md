# Data Model: Categories and Units

**Date**: 2026-05-12  
**Feature**: SPEC 04 - Categories and Units

## Entities

### 1. Category

Represents a product category.

**Table**: `categories`

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | uuid | PRIMARY KEY, DEFAULT gen_random_uuid() | Unique identifier |
| home_id | uuid | FOREIGN KEY (homes.id), NULLABLE | Reference to home (null for defaults) |
| name_ar | text | NOT NULL | Arabic name |
| name_en | text | NULLABLE | English name (optional) |
| type | text | NOT NULL, CHECK (type IN ('shopping', 'inventory', 'expense')) | Category type |
| icon | text | NULLABLE | Icon identifier |
| color | text | NULLABLE | Color hex code |
| sort_order | integer | DEFAULT 0 | Display order |
| is_default | boolean | DEFAULT false | Whether this is a system default |
| created_by | uuid | FOREIGN KEY (auth.users.id), NULLABLE | User who created |
| created_at | timestamptz | DEFAULT now() | Creation timestamp |
| updated_at | timestamptz | NULLABLE | Last update timestamp |
| deleted_at | timestamptz | NULLABLE | Soft delete timestamp |

**Constraints**:
- UNIQUE (home_id, name_ar) WHERE deleted_at IS NULL
- UNIQUE (home_id, name_en) WHERE name_en IS NOT NULL AND deleted_at IS NULL

**Relationships**:
- `home_id` → `homes.id`
- `created_by` → `auth.users.id`

### 2. Unit

Represents a measurement unit.

**Table**: `units`

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | uuid | PRIMARY KEY, DEFAULT gen_random_uuid() | Unique identifier |
| home_id | uuid | FOREIGN KEY (homes.id), NULLABLE | Reference to home (null for defaults) |
| name_ar | text | NOT NULL | Arabic name |
| name_en | text | NULLABLE | English name (optional) |
| symbol | text | NOT NULL | Unit symbol (kg, L, etc.) |
| type | text | NOT NULL, CHECK (type IN ('weight', 'volume', 'count', 'length')) | Unit type |
| is_default | boolean | DEFAULT false | Whether this is a system default |
| created_by | uuid | FOREIGN KEY (auth.users.id), NULLABLE | User who created |
| created_at | timestamptz | DEFAULT now() | Creation timestamp |
| updated_at | timestamptz | NULLABLE | Last update timestamp |
| deleted_at | timestamptz | NULLABLE | Soft delete timestamp |

**Constraints**:
- UNIQUE (home_id, name_ar) WHERE deleted_at IS NULL
- UNIQUE (home_id, name_en) WHERE name_en IS NOT NULL AND deleted_at IS NULL
- UNIQUE (home_id, symbol) WHERE deleted_at IS NULL

**Relationships**:
- `home_id` → `homes.id`
- `created_by` → `auth.users.id`

## RLS Policies

### categories

```sql
-- Users can view all default categories
CREATE POLICY "view_default_categories" ON categories
  FOR SELECT USING (is_default = true);

-- Users can view custom categories for their homes
CREATE POLICY "view_home_categories" ON categories
  FOR SELECT USING (
    home_id IS NOT NULL AND
    EXISTS (
      SELECT 1 FROM home_members
      WHERE home_members.home_id = categories.home_id
      AND home_members.user_id = auth.uid()
    )
  );

-- Owners/admins can create custom categories
CREATE POLICY "create_category" ON categories
  FOR INSERT WITH CHECK (
    home_id IS NOT NULL AND
    is_default = false AND
    EXISTS (
      SELECT 1 FROM home_members
      WHERE home_members.home_id = categories.home_id
      AND home_members.user_id = auth.uid()
      AND home_members.role IN ('owner', 'admin')
    )
  );

-- Owners/admins can update custom categories
CREATE POLICY "update_category" ON categories
  FOR UPDATE USING (
    home_id IS NOT NULL AND
    is_default = false AND
    EXISTS (
      SELECT 1 FROM home_members
      WHERE home_members.home_id = categories.home_id
      AND home_members.user_id = auth.uid()
      AND home_members.role IN ('owner', 'admin')
    )
  );

-- Owners/admins can delete custom categories
CREATE POLICY "delete_category" ON categories
  FOR DELETE USING (
    home_id IS NOT NULL AND
    is_default = false AND
    EXISTS (
      SELECT 1 FROM home_members
      WHERE home_members.home_id = categories.home_id
      AND home_members.user_id = auth.uid()
      AND home_members.role IN ('owner', 'admin')
    )
  );
```

### units

```sql
-- Users can view all default units
CREATE POLICY "view_default_units" ON units
  FOR SELECT USING (is_default = true);

-- Users can view custom units for their homes
CREATE POLICY "view_home_units" ON units
  FOR SELECT USING (
    home_id IS NOT NULL AND
    EXISTS (
      SELECT 1 FROM home_members
      WHERE home_members.home_id = units.home_id
      AND home_members.user_id = auth.uid()
    )
  );

-- Owners/admins can create custom units
CREATE POLICY "create_unit" ON units
  FOR INSERT WITH CHECK (
    home_id IS NOT NULL AND
    is_default = false AND
    EXISTS (
      SELECT 1 FROM home_members
      WHERE home_members.home_id = units.home_id
      AND home_members.user_id = auth.uid()
      AND home_members.role IN ('owner', 'admin')
    )
  );

-- Owners/admins can update custom units
CREATE POLICY "update_unit" ON units
  FOR UPDATE USING (
    home_id IS NOT NULL AND
    is_default = false AND
    EXISTS (
      SELECT 1 FROM home_members
      WHERE home_members.home_id = units.home_id
      AND home_members.user_id = auth.uid()
      AND home_members.role IN ('owner', 'admin')
    )
  );

-- Owners/admins can delete custom units
CREATE POLICY "delete_unit" ON units
  FOR DELETE USING (
    home_id IS NOT NULL AND
    is_default = false AND
    EXISTS (
      SELECT 1 FROM home_members
      WHERE home_members.home_id = units.home_id
      AND home_members.user_id = auth.uid()
      AND home_members.role IN ('owner', 'admin')
    )
  );
```

## Indexes

```sql
-- Categories
CREATE INDEX idx_categories_home_id ON categories(home_id);
CREATE INDEX idx_categories_type ON categories(type);
CREATE INDEX idx_categories_is_default ON categories(is_default);
CREATE INDEX idx_categories_deleted_at ON categories(deleted_at);

-- Units
CREATE INDEX idx_units_home_id ON units(home_id);
CREATE INDEX idx_units_type ON units(type);
CREATE INDEX idx_units_is_default ON units(is_default);
CREATE INDEX idx_units_deleted_at ON units(deleted_at);
```

## Default Data

### Default Categories (8 categories)

| name_ar | name_en | type | icon | color |
|---------|---------|------|------|-------|
| خضروات وفواكه | Fruits & Vegetables | shopping | 🥬 | #4CAF50 |
| لحوم ودواجن | Meat & Poultry | shopping | 🥩 | #F44336 |
| منتجات ألبان | Dairy Products | shopping | 🥛 | #2196F3 |
| مخبوزات | Bakery | shopping | 🍞 | #FF9800 |
| مشروبات | Beverages | shopping | 🥤 | #9C27B0 |
| منظفات | Cleaning | shopping | 🧹 | #607D8B |
| شخصية | Personal Care | shopping | 🧴 | #E91E63 |
| أخرى | Other | shopping | 📦 | #9E9E9E |

### Default Units (11 units)

| name_ar | name_en | symbol | type |
|---------|---------|--------|------|
| كيلوغرام | Kilogram | kg | weight |
| غرام | Gram | g | weight |
| لتر | Liter | L | volume |
| ملليلتر | Milliliter | mL | volume |
| قطعة | Piece | pc | count |
| علبة | Pack | pack | count |
| كرتون | Carton | carton | count |
| متر | Meter | m | length |
| سنتيمتر | Centimeter | cm | length |
| متر مربع | Square Meter | m² | length |
| عبوة | Bottle | bottle | count |
