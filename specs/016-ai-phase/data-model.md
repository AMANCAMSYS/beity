# Data Model: AI Smart Shopping Suggestions

**Date**: 2026-05-14  
**Spec**: [spec.md](./spec.md)  
**Research**: [research.md](./research.md)

## Overview

AI Phase 1 introduces **no new database tables**. All entities are transient (in-memory only) and suggestions are persisted only when the user confirms adding them — at which point they become regular `shopping_items` rows via the existing creation flow.

## Domain Entities (Flutter — In-Memory Only)

### AiSuggestionRequest

Represents the payload sent from Flutter to the Edge Function.

| Field          | Type           | Required | Constraints                                    |
|----------------|----------------|----------|------------------------------------------------|
| prompt         | String         | Yes      | Non-empty, max 500 characters                  |
| homeType       | String         | Yes      | e.g., "family", "students", "single", "office" |
| listTitle      | String         | Yes      | Non-empty                                      |
| existingItems  | List\<String\> | Yes      | Item names only, no IDs or metadata             |
| language       | String         | Yes      | "ar" or "en"                                   |

**Validation rules**:
- `prompt` must be trimmed and non-empty after trimming
- `prompt` max length: 500 characters
- `existingItems` max length: 100 items (truncate if more)
- `language` must be one of: `ar`, `en`

### AiSuggestion

Represents a single AI-generated suggestion item.

| Field    | Type    | Required | Constraints                             |
|----------|---------|----------|-----------------------------------------|
| name     | String  | Yes      | Non-empty, max 100 characters, trimmed  |
| quantity | double? | No       | If present, must be > 0 and <= 9999     |
| unit     | String? | No       | Max 20 characters                       |
| category | String? | No       | Max 50 characters                       |

**Validation rules**:
- `name` is required, trimmed, max 100 chars
- `quantity` defaults to 1.0 if null or invalid
- Unknown `unit`/`category` values are kept as display hints only (not mapped to `unit_id`/`category_id` unless exact match found)

### AiSuggestionResponse

Represents the full Edge Function response parsed by Flutter.

| Field       | Type                | Required | Constraints          |
|-------------|---------------------|----------|----------------------|
| suggestions | List\<AiSuggestion\>| Yes      | Max 20 items         |
| error       | String?             | No       | Present only on failure |

**State transitions (transient, UI-only)**:

```
idle → loading → (success | error)
         ↓
    success → user selects items → confirmed (items added to list)
         ↓
    success → user cancels → idle
```

## Edge Function Contract (Supabase)

### Function: `generate-shopping-suggestions`

**Input** (JSON body from Flutter):

```json
{
  "prompt": "items for a BBQ party",
  "homeType": "family",
  "listTitle": "Weekend Shopping",
  "existingItems": ["chicken", "rice", "bread"],
  "language": "en"
}
```

**Output — Success** (HTTP 200):

```json
{
  "suggestions": [
    { "name": "Charcoal", "quantity": 2, "unit": "kg", "category": "BBQ" },
    { "name": "Ketchup", "quantity": 1, "unit": "bottle" },
    { "name": "Paper plates", "quantity": 20, "unit": "pcs" }
  ]
}
```

**Output — Error** (HTTP 4xx/5xx):

```json
{
  "error": "Unable to generate suggestions. Please try again."
}
```

**Server-side validation**:
- Reject if `prompt` is empty or > 500 chars → 400
- Reject if `language` is not `ar` or `en` → 400
- Reject if `existingItems` has > 100 entries → 400
- Cap suggestions array at 20 items
- Truncate suggestion `name` at 100 chars
- Strip any fields not in the allowed schema

## Integration with Existing Tables

### shopping_items (existing — no changes)

AI-confirmed items are inserted via the existing `ShoppingListRepository.createShoppingItem()` method:

| ShoppingItem Field | Source from AiSuggestion        |
|--------------------|---------------------------------|
| name               | `suggestion.name`               |
| quantity           | `suggestion.quantity ?? 1.0`    |
| unitId             | Matched from `suggestion.unit` if possible, else null |
| categoryId         | Matched from `suggestion.category` if possible, else null |
| listId             | Current shopping list ID        |
| createdBy          | Current user ID (via auth)      |

### activity_logs (existing — no schema changes)

When user confirms adding AI suggestions:

| Field       | Value                                   |
|-------------|-----------------------------------------|
| home_id     | Current home ID                         |
| user_id     | Current user ID                         |
| action      | `ai_items_added`                        |
| entity_type | `shopping_list`                         |
| entity_id   | Shopping list UUID                      |
| entity_name | Shopping list title                     |
| metadata    | `{ "source": "ai_suggestion", "prompt": "<first 100 chars>", "items_count": N, "items": ["name1", "name2", ...] }` |

## Privacy Boundary Summary

| Data Type           | Sent to Edge Function | Sent to Gemini API |
|---------------------|----------------------|-------------------|
| User prompt         | ✅                    | ✅                 |
| Home type           | ✅                    | ✅                 |
| List title          | ✅                    | ✅                 |
| Existing item names | ✅                    | ✅                 |
| Language            | ✅                    | ✅                 |
| User ID             | ❌                    | ❌                 |
| Email / Phone       | ❌                    | ❌                 |
| Member names        | ❌                    | ❌                 |
| Auth tokens         | ❌ (transport only)   | ❌                 |
| Activity logs       | ❌                    | ❌                 |
| Expense data        | ❌                    | ❌                 |
