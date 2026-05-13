# Data Model: Shopping Items

**Feature**: 006-shopping-items  
**Date**: 2026-05-12  
**Status**: Complete

## Overview

This feature enhances the existing `shopping_items` and `item_templates` tables created in SPEC 05. No new tables are required. The data model focuses on the enhanced UI behaviors and business logic defined in the spec.

## Existing Tables (from SPEC 05)

### shopping_items

No schema changes required. Existing columns support all SPEC 06 requirements:

| Column | Type | Usage in SPEC 06 |
|--------|------|-------------------|
| id | UUID | Primary key |
| shopping_list_id | UUID | Groups items by list |
| name | VARCHAR(255) | Item name — autocomplete source, duplicate check |
| quantity | DECIMAL(10,2) | Displayed in autocomplete suggestions |
| unit_id | UUID | Displayed in autocomplete suggestions (via join) |
| category_id | UUID | Grouping key for category headers |
| price | DECIMAL(10,2) | Used for unpurchased-only running total |
| is_purchased | BOOLEAN | Sinks items to bottom of category group |
| purchased_by | UUID | Displayed in item details |
| purchased_at | TIMESTAMP | Displayed in item details |
| created_by | UUID | Audit field |
| created_at | TIMESTAMP | Audit field |
| updated_at | TIMESTAMP | Last-write-wins conflict resolution |

### item_templates

No schema changes required. Existing columns support all SPEC 06 requirements:

| Column | Type | Usage in SPEC 06 |
|--------|------|-------------------|
| id | UUID | Primary key |
| home_id | UUID | Scopes templates to home |
| name | VARCHAR(255) | Template name — autocomplete source |
| default_quantity | DECIMAL(10,2) | Pre-filled on Quick Add |
| default_unit_id | UUID | Pre-filled on Quick Add |
| default_category_id | UUID | Pre-filled on Quick Add |
| usage_count | INTEGER | Sort order for Quick Add list |
| created_by | UUID | Audit field |

## New Business Logic (no schema changes)

### 1. Duplicate Name Warning

**Trigger**: When inserting a new `shopping_items` row  
**Logic**: Client-side check — query existing items in the same `shopping_list_id` where `name` matches (case-insensitive)  
**Action**: Show warning dialog; if confirmed, proceed with insert  
**No database constraint**: Duplicates are allowed (per clarification)

### 2. Category Grouping

**Trigger**: When rendering items in `shopping_list_detail_screen`  
**Logic**: Group items by `category_id`; within each group, sort unpurchased first, then purchased  
**Implementation**: Presentation-layer grouping using Dart `groupBy()` + custom sort  
**Null category**: Items with `category_id = NULL` grouped under "Uncategorized"

### 3. Template Auto-Create on Add Only

**Trigger**: After inserting a new `shopping_items` row  
**Logic**: Check if `item_templates` row exists for (home_id, name):
- If exists: increment `usage_count`
- If not exists: create new template with item's name, quantity, unit_id, category_id  
**NOT triggered on update**: Editing an item does not modify templates

### 4. Running Price Total

**Trigger**: When rendering item list  
**Logic**: `SUM(price)` where `is_purchased = FALSE` and `price IS NOT NULL`  
**Implementation**: Computed in provider, displayed at bottom of list

### 5. Autocomplete Suggestions

**Trigger**: When user types in item name field  
**Logic**: Query two sources:
1. `item_templates` for home where `name ILIKE '%query%'`
2. `shopping_items` (distinct names) for lists in same home where `name ILIKE '%query%'`  
**Merge**: Combine results, deduplicate by name, limit to 10 suggestions  
**Display**: Each suggestion shows `name`, `quantity`, `unit` (via join)

## Entity Relationships (unchanged from SPEC 05)

```
homes (1) ──── (N) shopping_lists
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

## Data Volume Assumptions (unchanged)

- Up to 200 items per shopping list
- Up to 100 item templates per home
- Average 10 items purchased per list per week

## RLS Policies (unchanged from SPEC 05)

All existing RLS policies on `shopping_items` and `item_templates` remain valid. Home membership check via `shopping_lists` → `homes` → `home_members` chain is already in place.
