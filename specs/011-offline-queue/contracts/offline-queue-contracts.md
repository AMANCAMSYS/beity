# Offline Queue Contracts

**Feature**: Offline Queue (SPEC 011)  
**Date**: 2026-05-13  
**Status**: Complete

## Repository Contracts

### OfflineQueueRepository

Abstract interface for offline queue operations.

```dart
abstract class OfflineQueueRepository {
  /// Enqueue a new action for later sync
  Future<void> enqueueAction({
    required ActionType actionType,
    required EntityType entityType,
    required String entityId,
    required String homeId,
    required Map<String, dynamic> payload,
  });

  /// Get all queue entries for a home
  Future<List<QueueEntry>> getEntriesByHome(String homeId);

  /// Get queue entries filtered by sync status
  Future<List<QueueEntry>> getEntriesByStatus(SyncStatus status);

  /// Get pending entries count for a home
  Future<int> getPendingCount(String homeId);

  /// Get a specific queue entry by ID
  Future<QueueEntry?> getEntryById(int id);

  /// Update a queue entry's status
  Future<void> updateEntryStatus({
    required int entryId,
    required SyncStatus status,
    String? errorMessage,
  });

  /// Delete a queue entry (after successful sync)
  Future<void> deleteEntry(int entryId);

  /// Delete all completed entries for a home
  Future<void> deleteCompletedEntries(String homeId);

  /// Get all failed entries for a home (for manual retry)
  Future<List<QueueEntry>> getFailedEntries(String homeId);
}
```

---

### ConnectivityRepository

Abstract interface for connectivity detection.

```dart
abstract class ConnectivityRepository {
  /// Get current connectivity status
  Future<DeviceSyncStatus> getCurrentStatus();

  /// Stream of connectivity status changes
  Stream<DeviceSyncStatus> get statusStream;

  /// Check if Supabase server is reachable
  Future<bool> isServerReachable();
}
```

---

## Use Case Contracts

### EnqueueActionUseCase

Enqueues a user action for later sync.

```dart
class EnqueueActionUseCase {
  Future<void> execute({
    required ActionType actionType,
    required EntityType entityType,
    required String entityId,
    required String homeId,
    required Map<String, dynamic> payload,
  });
}
```

**Business Rules**:
- Always enqueue when device is offline
- When online, execute action directly (skip queue)
- Update local UI optimistically after enqueueing

---

### SyncQueueUseCase

Syncs all pending queue entries when connectivity is restored.

```dart
class SyncQueueUseCase {
  Future<SyncResult> execute(String homeId);
}

class SyncResult {
  final int successCount;
  final int failedCount;
  final List<SyncConflict> conflicts;
}
```

**Business Rules**:
- Process entries in chronological order (oldest first)
- For each entry: fetch current server state, apply last-write-wins
- Delete entry on success, mark as failed on max retries
- Return summary of sync results

---

### RetryFailedActionUseCase

Retries a single failed queue entry.

```dart
class RetryFailedActionUseCase {
  Future<void> execute(int entryId);
}
```

**Business Rules**:
- Only retry entries with `failed` status
- Reset retry counter before retrying
- Delegate to SyncQueueUseCase for actual sync logic

---

### GetPendingCountUseCase

Returns the count of pending queue entries.

```dart
class GetPendingCountUseCase {
  Future<int> execute(String homeId);
}
```

**Business Rules**:
- Count entries with `pending` or `syncing` status
- Used for UI badge/indicator display

---

### GetQueueEntriesUseCase

Returns queue entries for display.

```dart
class GetQueueEntriesUseCase {
  Future<List<QueueEntry>> execute({
    required String homeId,
    SyncStatus? statusFilter,
  });
}
```

**Business Rules**:
- Return entries ordered by createdAt ascending
- Optionally filter by status
- Used for queue status display

---

## Provider Contracts

### OfflineQueueProvider

Riverpod provider for offline queue state.

```dart
@riverpod
class OfflineQueue extends _$OfflineQueue {
  @override
  Future<List<QueueEntry>> build(String homeId);

  Future<void> enqueueAction({...});
  Future<void> retryEntry(int entryId);
  Future<void> syncAll();
}
```

---

### ConnectivityProvider

Riverpod provider for connectivity status.

```dart
@riverpod
class Connectivity extends _$Connectivity {
  @override
  Stream<DeviceSyncStatus> build();

  Future<DeviceSyncStatus> getCurrentStatus();
}
```

---

### SyncStatusProvider

Riverpod provider for aggregate sync status.

```dart
@riverpod
class SyncStatus extends _$SyncStatus {
  @override
  Future<SyncStatusState> build(String homeId);
}

class SyncStatusState {
  final DeviceSyncStatus deviceStatus;
  final int pendingCount;
  final int failedCount;
  final bool isSyncing;
}
```

---

## Action Payload Schemas

### addItem Payload

```json
{
  "listId": "uuid",
  "name": "string",
  "quantity": 1.0,
  "unit": "string",
  "categoryId": "uuid",
  "notes": "string"
}
```

### updateItem Payload

```json
{
  "itemId": "uuid",
  "fields": {
    "name": "string",
    "quantity": 1.0,
    "unit": "string",
    "categoryId": "uuid",
    "notes": "string"
  }
}
```

### deleteItem Payload

```json
{
  "itemId": "uuid"
}
```

### markPurchased Payload

```json
{
  "itemId": "uuid",
  "purchasedAt": "2026-05-13T10:30:00Z"
}
```

### updateQuantity Payload

```json
{
  "itemId": "uuid",
  "quantity": 2.0
}
```
