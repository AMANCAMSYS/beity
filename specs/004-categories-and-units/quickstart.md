# Quickstart: Categories and Units

**Date**: 2026-05-12  
**Feature**: SPEC 04 - Categories and Units

## Overview

This feature implements the categories and units management system for Beity. Users can view default categories and units, create custom ones for their homes, and manage them with full CRUD operations.

## Prerequisites

- Flutter SDK installed
- Supabase project configured
- Existing Beity app running

## Setup Steps

### 1. Database Setup

Run the following SQL in Supabase SQL Editor:

```sql
-- Create categories table
CREATE TABLE IF NOT EXISTS categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  home_id UUID REFERENCES homes(id) ON DELETE CASCADE,
  name_ar TEXT NOT NULL,
  name_en TEXT,
  type TEXT NOT NULL CHECK (type IN ('shopping', 'inventory', 'expense')),
  icon TEXT,
  color TEXT,
  sort_order INTEGER DEFAULT 0,
  is_default BOOLEAN DEFAULT false,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ,
  UNIQUE (home_id, name_ar) WHERE deleted_at IS NULL,
  UNIQUE (home_id, name_en) WHERE name_en IS NOT NULL AND deleted_at IS NULL
);

-- Create units table
CREATE TABLE IF NOT EXISTS units (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  home_id UUID REFERENCES homes(id) ON DELETE CASCADE,
  name_ar TEXT NOT NULL,
  name_en TEXT,
  symbol TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('weight', 'volume', 'count', 'length')),
  is_default BOOLEAN DEFAULT false,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ,
  UNIQUE (home_id, name_ar) WHERE deleted_at IS NULL,
  UNIQUE (home_id, name_en) WHERE name_en IS NOT NULL AND deleted_at IS NULL,
  UNIQUE (home_id, symbol) WHERE deleted_at IS NULL
);

-- Enable RLS
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE units ENABLE ROW LEVEL SECURITY;

-- Create indexes
CREATE INDEX idx_categories_home_id ON categories(home_id);
CREATE INDEX idx_categories_type ON categories(type);
CREATE INDEX idx_categories_is_default ON categories(is_default);
CREATE INDEX idx_units_home_id ON units(home_id);
CREATE INDEX idx_units_type ON units(type);
CREATE INDEX idx_units_is_default ON units(is_default);

-- Insert default categories
INSERT INTO categories (name_ar, name_en, type, icon, color, is_default) VALUES
  ('خضروات وفواكه', 'Fruits & Vegetables', 'shopping', '🥬', '#4CAF50', true),
  ('لحوم ودواجن', 'Meat & Poultry', 'shopping', '🥩', '#F44336', true),
  ('منتجات ألبان', 'Dairy Products', 'shopping', '🥛', '#2196F3', true),
  ('مخبوزات', 'Bakery', 'shopping', '🍞', '#FF9800', true),
  ('مشروبات', 'Beverages', 'shopping', '🥤', '#9C27B0', true),
  ('منظفات', 'Cleaning', 'shopping', '🧹', '#607D8B', true),
  ('شخصية', 'Personal Care', 'shopping', '🧴', '#E91E63', true),
  ('أخرى', 'Other', 'shopping', '📦', '#9E9E9E', true);

-- Insert default units
INSERT INTO units (name_ar, name_en, symbol, type, is_default) VALUES
  ('كيلوغرام', 'Kilogram', 'kg', 'weight', true),
  ('غرام', 'Gram', 'g', 'weight', true),
  ('لتر', 'Liter', 'L', 'volume', true),
  ('ملليلتر', 'Milliliter', 'mL', 'volume', true),
  ('قطعة', 'Piece', 'pc', 'count', true),
  ('علبة', 'Pack', 'pack', 'count', true),
  ('كرتون', 'Carton', 'carton', 'count', true),
  ('متر', 'Meter', 'm', 'length', true),
  ('سنتيمتر', 'Centimeter', 'cm', 'length', true),
  ('متر مربع', 'Square Meter', 'm²', 'length', true),
  ('عبوة', 'Bottle', 'bottle', 'count', true);
```

### 2. Flutter Dependencies

No new dependencies required - using existing Supabase Flutter.

### 3. Feature Structure

Create the following directory structure:

```
lib/features/categories/
├── data/
│   ├── models/
│   │   ├── category_model.dart
│   │   └── unit_model.dart
│   └── repositories/
│       ├── category_repository.dart
│       └── unit_repository.dart
├── domain/
│   ├── entities/
│   │   ├── category.dart
│   │   └── unit.dart
│   └── usecases/
│       ├── get_categories_usecase.dart
│       ├── create_category_usecase.dart
│       ├── update_category_usecase.dart
│       ├── delete_category_usecase.dart
│       ├── get_units_usecase.dart
│       ├── create_unit_usecase.dart
│       ├── update_unit_usecase.dart
│       └── delete_unit_usecase.dart
└── presentation/
    ├── providers/
    │   ├── categories_provider.dart
    │   └── units_provider.dart
    ├── screens/
    │   ├── categories_list_screen.dart
    │   ├── create_category_screen.dart
    │   ├── units_list_screen.dart
    │   └── create_unit_screen.dart
    └── widgets/
        ├── category_card_widget.dart
        └── unit_card_widget.dart
```

## Testing

### Unit Tests

```bash
flutter test test/unit/features/categories/
```

### Integration Tests

```bash
flutter test test/integration/features/categories/
```

### Widget Tests

```bash
flutter test test/widget/features/categories/
```

## Verification

1. **View Categories**: Verify all 8 default categories appear
2. **Create Category**: Create custom category, verify it appears
3. **Edit Category**: Edit custom category, verify changes persist
4. **Delete Category**: Delete custom category, verify products become uncategorized
5. **View Units**: Verify all 11 default units appear
6. **Create Unit**: Create custom unit, verify it appears
7. **Edit Unit**: Edit custom unit, verify changes persist
8. **Delete Unit**: Delete custom unit, verify products become no unit

## Next Steps

After completing this feature:
1. Run `flutter analyze` to check for issues
2. Run `flutter test` to verify all tests pass
3. Proceed to SPEC 05 - Shopping Lists
