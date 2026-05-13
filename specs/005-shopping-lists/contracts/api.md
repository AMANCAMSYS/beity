# API Contracts: Shopping Lists

**Feature**: 005-shopping-lists  
**Date**: 2026-05-12  
**Status**: Complete

## Supabase API Contracts

### shopping_lists

#### List Shopping Lists for Home

**Endpoint**: `GET /rest/v1/shopping_lists`  
**Headers**: `Authorization: Bearer <jwt>`  
**Query Parameters**:
- `home_id=eq.<uuid>` - Filter by home
- `status=eq.active` - Filter by status
- `order=updated_at.desc` - Sort by last updated

**Response**: 200 OK
```json
[
  {
    "id": "uuid",
    "home_id": "uuid",
    "name": "Weekly Groceries",
    "description": "Items for this week",
    "created_by": "uuid",
    "status": "active",
    "created_at": "2026-05-12T10:00:00Z",
    "updated_at": "2026-05-12T10:00:00Z",
    "deleted_at": null
  }
]
```

#### Create Shopping List

**Endpoint**: `POST /rest/v1/shopping_lists`  
**Headers**: `Authorization: Bearer <jwt>`, `Content-Type: application/json`  
**Body**:
```json
{
  "home_id": "uuid",
  "name": "Weekly Groceries",
  "description": "Items for this week"
}
```

**Response**: 201 Created
```json
{
  "id": "uuid",
  "home_id": "uuid",
  "name": "Weekly Groceries",
  "description": "Items for this week",
  "created_by": "uuid",
  "status": "active",
  "created_at": "2026-05-12T10:00:00Z",
  "updated_at": "2026-05-12T10:00:00Z",
  "deleted_at": null
}
```

#### Update Shopping List

**Endpoint**: `PATCH /rest/v1/shopping_lists?id=eq.<uuid>`  
**Headers**: `Authorization: Bearer <jwt>`, `Content-Type: application/json`  
**Body**:
```json
{
  "name": "Updated Name",
  "description": "Updated description",
  "status": "archived"
}
```

**Response**: 200 OK (updated record)

#### Delete Shopping List (Soft)

**Endpoint**: `PATCH /rest/v1/shopping_lists?id=eq.<uuid>`  
**Headers**: `Authorization: Bearer <jwt>`, `Content-Type: application/json`  
**Body**:
```json
{
  "deleted_at": "2026-05-12T10:00:00Z"
}
```

**Response**: 200 OK

---

### shopping_items

#### List Items for Shopping List

**Endpoint**: `GET /rest/v1/shopping_items`  
**Headers**: `Authorization: Bearer <jwt>`  
**Query Parameters**:
- `shopping_list_id=eq.<uuid>` - Filter by list
- `order=is_purchased.asc,name.asc` - Sort by purchase status then name

**Response**: 200 OK
```json
[
  {
    "id": "uuid",
    "shopping_list_id": "uuid",
    "name": "Milk",
    "quantity": 2.0,
    "unit_id": "uuid",
    "category_id": "uuid",
    "price": 15.50,
    "currency": "SAR",
    "notes": "Full fat",
    "is_purchased": false,
    "purchased_by": null,
    "purchased_at": null,
    "created_by": "uuid",
    "created_at": "2026-05-12T10:00:00Z",
    "updated_at": "2026-05-12T10:00:00Z"
  }
]
```

#### Add Item to Shopping List

**Endpoint**: `POST /rest/v1/shopping_items`  
**Headers**: `Authorization: Bearer <jwt>`, `Content-Type: application/json`  
**Body**:
```json
{
  "shopping_list_id": "uuid",
  "name": "Milk",
  "quantity": 2.0,
  "unit_id": "uuid",
  "category_id": "uuid",
  "price": 15.50,
  "currency": "SAR",
  "notes": "Full fat"
}
```

**Response**: 201 Created (created record)

#### Update Shopping Item

**Endpoint**: `PATCH /rest/v1/shopping_items?id=eq.<uuid>`  
**Headers**: `Authorization: Bearer <jwt>`, `Content-Type: application/json`  
**Body**:
```json
{
  "quantity": 3.0,
  "is_purchased": true,
  "purchased_by": "uuid",
  "purchased_at": "2026-05-12T10:00:00Z"
}
```

**Response**: 200 OK (updated record)

#### Delete Shopping Item

**Endpoint**: `DELETE /rest/v1/shopping_items?id=eq.<uuid>`  
**Headers**: `Authorization: Bearer <jwt>`  
**Response**: 204 No Content

---

### item_templates

#### List Templates for Home

**Endpoint**: `GET /rest/v1/item_templates`  
**Headers**: `Authorization: Bearer <jwt>`  
**Query Parameters**:
- `home_id=eq.<uuid>` - Filter by home
- `order=usage_count.desc` - Sort by usage

**Response**: 200 OK
```json
[
  {
    "id": "uuid",
    "home_id": "uuid",
    "name": "Milk",
    "default_quantity": 1.0,
    "default_unit_id": "uuid",
    "default_category_id": "uuid",
    "usage_count": 15,
    "created_by": "uuid",
    "created_at": "2026-05-12T10:00:00Z",
    "updated_at": "2026-05-12T10:00:00Z"
  }
]
```

#### Create Template

**Endpoint**: `POST /rest/v1/item_templates`  
**Headers**: `Authorization: Bearer <jwt>`, `Content-Type: application/json`  
**Body**:
```json
{
  "home_id": "uuid",
  "name": "Milk",
  "default_quantity": 1.0,
  "default_unit_id": "uuid",
  "default_category_id": "uuid"
}
```

**Response**: 201 Created (created record)

#### Update Template Usage Count

**Endpoint**: `PATCH /rest/v1/item_templates?id=eq.<uuid>`  
**Headers**: `Authorization: Bearer <jwt>`, `Content-Type: application/json`  
**Body**:
```json
{
  "usage_count": 16
}
```

**Response**: 200 OK (updated record)

---

## Realtime Subscriptions

### Shopping Items Changes

**Channel**: `shopping_items:<shopping_list_id>`  
**Events**: `INSERT`, `UPDATE`, `DELETE`  
**Filter**: `shopping_list_id=eq.<uuid>`

**Payload Example**:
```json
{
  "eventType": "INSERT",
  "new": {
    "id": "uuid",
    "shopping_list_id": "uuid",
    "name": "Milk",
    "quantity": 2.0,
    "is_purchased": false
  },
  "old": {}
}
```

### Shopping Lists Changes

**Channel**: `shopping_lists:<home_id>`  
**Events**: `INSERT`, `UPDATE`, `DELETE`  
**Filter**: `home_id=eq.<uuid>`

---

## Error Responses

### 401 Unauthorized
```json
{
  "message": "Invalid JWT",
  "code": "INVALID_JWT"
}
```

### 403 Forbidden
```json
{
  "message": "Insufficient permissions",
  "code": "INSUFFICIENT_PERMISSIONS"
}
```

### 404 Not Found
```json
{
  "message": "Resource not found",
  "code": "NOT_FOUND"
}
```

### 409 Conflict
```json
{
  "message": "Duplicate resource",
  "code": "DUPLICATE_RESOURCE"
}
```
