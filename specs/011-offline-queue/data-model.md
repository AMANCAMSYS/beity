# Data Model: Offline Queue

**Feature**: Offline Queue (SPEC 011)  
**Date**: 2026-05-13  
**Status**: Complete

## Entities

### QueueEntry (Isar Collection)

Represents a single queued action waiting to be synced.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | int | Auto | Isar auto-increment primary key |
| actionType | ActionType | Yes | Type of action performed (add, update, delete, markPurchased, updateQuantity) |
| entityType | EntityType | Yes | Type of entity acted upon (shoppingItem, shoppingList) |
| entityId | String | Yes | UUID of the entity being acted upon |
| homeId | String | Yes | UUID of the home this action belongs to |
| payload | Map<String, dynamic> | Yes | Serialized action data (item fields, list fields, etc.) |
| createdAt | DateTime | Yes | Timestamp when the action was performed locally |
| syncStatus | SyncStatus | Yes | Current sync state (pending, syncing, failed) |
| retryCount | int | Yes | Number of sync attempts made (default: 0) |
| lastRetryAt | DateTime? | No | Timestamp of last sync attempt |
| errorMessage | String? | No | Error message if sync failed |

**Indexes**:
- `syncStatus` — for filtering by status
- `homeId` — for filtering by home
- `createdAt` — for ordering by timestamp

**State Transitions**:
```
pending → syncing → [completed (deleted)] or failed
failed → syncing → [completed (deleted)] or failed
```

---

### ActionType (Enum)

Types of actions that can be queued.

| Value | Description |
|-------|-------------|
| addItem | Add a new shopping item to a list |
| updateItem | Update an existing shopping item's fields |
| deleteItem | Delete a shopping item |
| markPurchased | Mark an item as purchased |
| updateQuantity | Update an item's quantity |

---

### EntityType (Enum)

Types of entities that can be acted upon.

| Value | Description |
|-------|-------------|
| shoppingItem | A shopping item in a list |
| shoppingList | A shopping list (for list-level operations) |

---

### SyncStatus (Enum)

States of a queue entry.

| Value | Description |
|-------|-------------|
| pending | Waiting to be synced |
| syncing | Currently being synced |
| failed | Sync failed after max retries |

**Note**: `completed` is not stored — entries are deleted upon successful sync.

---

### DeviceSyncStatus (Enum)

Overall sync state of the device.

| Value | Description |
|-------|-------------|
| online | Connected with no pending actions |
| onlineWithPending | Connected but has pending queue entries |
| offline | Not connected (network or server unreachable) |

## Relationships

```
QueueEntry
  ├── belongs to → Home (via homeId)
  ├── acts on → ShoppingItem (via entityId when entityType = shoppingItem)
  └── acts on → ShoppingList (via entityId when entityType = shoppingList)
```

**Note**: QueueEntry does not have a foreign key to Supabase tables since it's a local-only Isar collection. References are by UUID only.

## Validation Rules

1. **actionType** must be a valid ActionType enum value
2. **entityType** must be a valid EntityType enum value
3. **entityId** must be a valid UUID format
4. **homeId** must be a valid UUID format
5. **payload** must not be null (can be empty map)
6. **createdAt** must not be in the future
7. **retryCount** must be >= 0

## Data Volume Assumptions

- Typical queue size: 0-50 entries per device
- Maximum supported: 200 entries without performance degradation
- Entry size: ~1-2 KB per entry
- Total storage: < 1 MB for typical usage
