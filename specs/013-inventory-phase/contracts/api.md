# API Contracts: Inventory Phase

**Feature**: 013-inventory-phase  
**Date**: 2026-05-13  
**Status**: Complete

## Supabase API Contracts

### inventory_items

#### List Inventory Items for Home

**Endpoint**: `GET /rest/v1/inventory_items`  
**Headers**: `Authorization: Bearer <jwt>`  
**Query Parameters**:
- `home_id=eq.<uuid>` - Filter by home
- `deleted_at=is.null` - Exclude soft-deleted items
- `order=category_id.asc,name.asc` - Sort by category then name

**Response**: 200 OK
```json
[
  {
    "id": "uuid",
    "home_id": "uuid",
    "name": "Rice",
    "quantity": 2.50,
    "unit_id": "uuid",
    "category_id": "uuid",
    "min_quantity": 1.00,
    "notes": "Basmati, stored in pantry",
    "created_by": "uuid",
    "updated_by": "uuid",
    "created_at": "2026-05-13T10:00:00Z",
    "updated_at": "2026-05-13T10:00:00Z",
    "deleted_at": null
  }
]
```

#### Get Single Inventory Item

**Endpoint**: `GET /rest/v1/inventory_items?id=eq.<uuid>`  
**Headers**: `Authorization: Bearer <jwt>`  

**Response**: 200 OK
```json
{
  "id": "uuid",
  "home_id": "uuid",
  "name": "Rice",
  "quantity": 2.50,
  "unit_id": "uuid",
  "category_id": "uuid",
  "min_quantity": 1.00,
  "notes": "Basmati, stored in pantry",
  "created_by": "uuid",
  "updated_by": "uuid",
  "created_at": "2026-05-13T10:00:00Z",
  "updated_at": "2026-05-13T10:00:00Z",
  "deleted_at": null
}
```

#### Add Inventory Item

**Endpoint**: `POST /rest/v1/inventory_items`  
**Headers**: `Authorization: Bearer <jwt>`, `Content-Type: application/json`  
**Body**:
```json
{
  "home_id": "uuid",
  "name": "Rice",
  "quantity": 2.50,
  "unit_id": "uuid",
  "category_id": "uuid",
  "min_quantity": 1.00,
  "notes": "Basmati, stored in pantry"
}
```

**Response**: 201 Created
```json
{
  "id": "uuid",
  "home_id": "uuid",
  "name": "Rice",
  "quantity": 2.50,
  "unit_id": "uuid",
  "category_id": "uuid",
  "min_quantity": 1.00,
  "notes": "Basmati, stored in pantry",
  "created_by": "uuid",
  "updated_by": "uuid",
  "created_at": "2026-05-13T10:00:00Z",
  "updated_at": "2026-05-13T10:00:00Z",
  "deleted_at": null
}
```

#### Update Inventory Item

**Endpoint**: `PATCH /rest/v1/inventory_items?id=eq.<uuid>`  
**Headers**: `Authorization: Bearer <jwt>`, `Content-Type: application/json`  
**Body** (partial update):
```json
{
  "quantity": 3.00,
  "updated_by": "uuid"
}
```

**Response**: 200 OK
```json
{
  "id": "uuid",
  "home_id": "uuid",
  "name": "Rice",
  "quantity": 3.00,
  "unit_id": "uuid",
  "category_id": "uuid",
  "min_quantity": 1.00,
  "notes": "Basmati, stored in pantry",
  "created_by": "uuid",
  "updated_by": "uuid",
  "created_at": "2026-05-13T10:00:00Z",
  "updated_at": "2026-05-13T10:05:00Z",
  "deleted_at": null
}
```

#### Soft-Delete Inventory Item

**Endpoint**: `PATCH /rest/v1/inventory_items?id=eq.<uuid>`  
**Headers**: `Authorization: Bearer <jwt>`, `Content-Type: application/json`  
**Body**:
```json
{
  "deleted_at": "2026-05-13T12:00:00Z"
}
```

**Response**: 200 OK

#### Search Inventory Items by Name (Auto-Suggest)

**Endpoint**: `GET /rest/v1/inventory_items`  
**Headers**: `Authorization: Bearer <jwt>`  
**Query Parameters**:
- `home_id=eq.<uuid>`
- `name=ilike.*search_term*`
- `deleted_at=is.null`
- `limit=10`

**Response**: 200 OK (array of matching items)

---

### inventory_transactions

#### List Transactions for an Item

**Endpoint**: `GET /rest/v1/inventory_transactions`  
**Headers**: `Authorization: Bearer <jwt>`  
**Query Parameters**:
- `inventory_item_id=eq.<uuid>`
- `order=created_at.desc`
- `limit=50`

**Response**: 200 OK
```json
[
  {
    "id": "uuid",
    "inventory_item_id": "uuid",
    "home_id": "uuid",
    "previous_quantity": 2.50,
    "new_quantity": 3.00,
    "change_reason": "manual_update",
    "changed_by": "uuid",
    "created_at": "2026-05-13T10:05:00Z"
  }
]
```

#### Create Transaction (append-only)

**Endpoint**: `POST /rest/v1/inventory_transactions`  
**Headers**: `Authorization: Bearer <jwt>`, `Content-Type: application/json`  
**Body**:
```json
{
  "inventory_item_id": "uuid",
  "home_id": "uuid",
  "previous_quantity": 2.50,
  "new_quantity": 3.00,
  "change_reason": "manual_update"
}
```

**Response**: 201 Created

---

### Realtime Subscriptions

#### Subscribe to Inventory Changes

```dart
supabase
  .from('inventory_items')
  .stream(primaryKey: ['id'])
  .eq('home_id', homeId)
  .eq('deleted_at', null)
  .listen((data) {
    // Update local state with new inventory items
  });
```

#### Subscribe to Transaction History

```dart
supabase
  .from('inventory_transactions')
  .stream(primaryKey: ['id'])
  .eq('inventory_item_id', itemId)
  .order('created_at', ascending: false)
  .limit(50)
  .listen((data) {
    // Update transaction history view
  });
```

---

## Error Responses

All endpoints return standard Supabase/PostgREST error responses:

| Status | Meaning | Example |
|--------|---------|---------|
| 401 | Unauthorized (no valid JWT) | `{"message": "JWT expired"}` |
| 403 | Forbidden (RLS policy denied) | `{"message": "Permission denied"}` |
| 409 | Conflict (unique constraint violation) | `{"message": "duplicate key value"}` |
| 422 | Validation error (check constraint) | `{"message": "violates check constraint"}` |
