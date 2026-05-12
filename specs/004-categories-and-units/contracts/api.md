# API Contract: Categories and Units

**Date**: 2026-05-12  
**Feature**: SPEC 04 - Categories and Units

## Supabase Tables

### categories

**Operations**:

| Operation | Method | Description |
|-----------|--------|-------------|
| Get Categories | SELECT | List categories (defaults + home custom) |
| Create Category | INSERT | Create custom category |
| Update Category | UPDATE | Update custom category |
| Delete Category | DELETE | Soft delete custom category |

### units

**Operations**:

| Operation | Method | Description |
|-----------|--------|-------------|
| Get Units | SELECT | List units (defaults + home custom) |
| Create Unit | INSERT | Create custom unit |
| Update Unit | UPDATE | Update custom unit |
| Delete Unit | DELETE | Soft delete custom unit |

## Supabase Functions

### get_categories

**Purpose**: Get all categories for a home (defaults + custom)  
**Parameters**:
- `p_home_id` (uuid): Home ID
- `p_type` (text, optional): Filter by type

**Returns**: List of categories

### create_category

**Purpose**: Create custom category  
**Parameters**:
- `p_home_id` (uuid): Home ID
- `p_name_ar` (text): Arabic name
- `p_name_en` (text, optional): English name
- `p_type` (text): Category type
- `p_icon` (text, optional): Icon identifier
- `p_color` (text, optional): Color hex code

**Returns**: category record

**Validations**:
- User is owner/admin of home
- name_ar is unique within home
- name_en is unique within home (if provided)

### update_category

**Purpose**: Update custom category  
**Parameters**:
- `p_category_id` (uuid): Category ID
- `p_name_ar` (text, optional): Arabic name
- `p_name_en` (text, optional): English name
- `p_icon` (text, optional): Icon identifier
- `p_color` (text, optional): Color hex code
- `p_sort_order` (integer, optional): Display order

**Returns**: category record

**Validations**:
- Category is not default
- User is owner/admin of home
- name_ar is unique within home (if changed)
- name_en is unique within home (if changed)

### delete_category

**Purpose**: Soft delete custom category  
**Parameters**:
- `p_category_id` (uuid): Category ID

**Returns**: void

**Validations**:
- Category is not default
- User is owner/admin of home
- Warn if category has products

### get_units

**Purpose**: Get all units for a home (defaults + custom)  
**Parameters**:
- `p_home_id` (uuid): Home ID
- `p_type` (text, optional): Filter by type

**Returns**: List of units

### create_unit

**Purpose**: Create custom unit  
**Parameters**:
- `p_home_id` (uuid): Home ID
- `p_name_ar` (text): Arabic name
- `p_name_en` (text, optional): English name
- `p_symbol` (text): Unit symbol
- `p_type` (text): Unit type

**Returns**: unit record

**Validations**:
- User is owner/admin of home
- name_ar is unique within home
- symbol is unique within home

### update_unit

**Purpose**: Update custom unit  
**Parameters**:
- `p_unit_id` (uuid): Unit ID
- `p_name_ar` (text, optional): Arabic name
- `p_name_en` (text, optional): English name
- `p_symbol` (text, optional): Unit symbol

**Returns**: unit record

**Validations**:
- Unit is not default
- User is owner/admin of home
- name_ar is unique within home (if changed)
- symbol is unique within home (if changed)

### delete_unit

**Purpose**: Soft delete custom unit  
**Parameters**:
- `p_unit_id` (uuid): Unit ID

**Returns**: void

**Validations**:
- Unit is not default
- User is owner/admin of home
- Warn if unit is used by products

## Realtime Subscriptions

### categories

**Channel**: `categories:home_id={home_id}`  
**Events**: INSERT, UPDATE, DELETE  
**Use Case**: Live updates when categories change

### units

**Channel**: `units:home_id={home_id}`  
**Events**: INSERT, UPDATE, DELETE  
**Use Case**: Live updates when units change

## Error Codes

| Code | Description |
|------|-------------|
| CATEGORY_NOT_FOUND | Category not found |
| CATEGORY_IS_DEFAULT | Cannot modify default category |
| CATEGORY_NAME_EXISTS | Category name already exists |
| UNIT_NOT_FOUND | Unit not found |
| UNIT_IS_DEFAULT | Cannot modify default unit |
| UNIT_NAME_EXISTS | Unit name already exists |
| UNIT_SYMBOL_EXISTS | Unit symbol already exists |
| NOT_AUTHORIZED | User not authorized for action |
