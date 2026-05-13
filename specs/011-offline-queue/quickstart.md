# Quickstart: Offline Queue

**Feature**: Offline Queue (SPEC 011)  
**Date**: 2026-05-13  
**Status**: Complete

## Overview

The offline queue captures shopping list actions when the device loses connectivity, persists them locally using Isar, and syncs automatically when connectivity is restored.

## Setup

### 1. Add Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  isar: ^3.1.0
  isar_flutter_libs: ^3.1.0
  connectivity_plus: ^5.0.0

dev_dependencies:
  isar_generator: ^3.1.0
  build_runner: ^2.4.0
```

### 2. Initialize Isar

Add to `lib/main.dart` or app initialization:

```dart
final isar = await Isar.open([
  QueueEntrySchema,
]);
```

### 3. Register Providers

Add to Riverpod provider scope:

```dart
ProviderScope(
  overrides: [
    isarProvider.overrideWithValue(isar),
  ],
  child: MyApp(),
)
```

## Usage Examples

### Enqueue an Action (When Offline)

```dart
final enqueueUseCase = ref.read(enqueueActionUseCaseProvider);

await enqueueUseCase.execute(
  actionType: ActionType.addItem,
  entityType: EntityType.shoppingItem,
  entityId: newItemId,
  homeId: currentHomeId,
  payload: {
    'listId': shoppingListId,
    'name': 'Milk',
    'quantity': 2.0,
    'unit': 'liter',
    'categoryId': dairyCategoryId,
  },
);
```

### Display Pending Count

```dart
final pendingCount = ref.watch(pendingCountProvider(homeId));

// In widget tree:
if (pendingCount > 0) {
  SyncStatusBanner(count: pendingCount)
}
```

### Show Sync Indicator on Items

```dart
final queueEntries = ref.watch(queueEntriesProvider(homeId));

// Check if item has pending changes
final hasPending = queueEntries.any(
  (e) => e.entityId == itemId && e.syncStatus == SyncStatus.pending,
);

// In widget:
ShoppingItemCard(
  item: item,
  showPendingIndicator: hasPending,
)
```

### Manual Retry Failed Entry

```dart
final retryUseCase = ref.read(retryFailedActionUseCaseProvider);

await retryUseCase.execute(failedEntryId);
```

## UI Components

### PendingSyncIndicator

Small icon/badge showing an item has unsynced changes.

```dart
PendingSyncIndicator()  // Shows cloud-off icon with pending color
```

### SyncStatusBanner

Top banner showing overall sync status.

```dart
SyncStatusBanner(
  pendingCount: 5,
  failedCount: 1,
  onRetryAll: () => retryAll(),
)
```

### OfflineModeIndicator

Prominent indicator when device is offline.

```dart
OfflineModeIndicator()  // Shows "You're offline" message
```

## Arabic RTL Support

All widgets use `Directionality.of(context)` to adapt layout:

- Pending indicators align to the appropriate side
- Banner text aligns correctly
- Status messages display in Arabic when locale is ar

## Testing

### Unit Tests

```dart
test('enqueue action stores locally when offline', () async {
  // Arrange
  when(connectivityRepo.getCurrentStatus())
    .thenAnswer((_) async => DeviceSyncStatus.offline);
  
  // Act
  await enqueueUseCase.execute(
    actionType: ActionType.addItem,
    entityType: EntityType.shoppingItem,
    entityId: 'test-id',
    homeId: 'home-id',
    payload: {'name': 'Test Item'},
  );
  
  // Assert
  verify(queueRepo.enqueueAction(...)).called(1);
});
```

### Integration Test

```dart
testWidgets('offline queue syncs when connectivity restored', (tester) async {
  // 1. Enable airplane mode
  // 2. Add items to shopping list
  // 3. Verify pending indicators appear
  // 4. Disable airplane mode
  // 5. Verify items sync and indicators disappear
});
```

## Performance Notes

- Queue writes: < 1s (Isar transactional writes)
- Sync on reconnect: < 30s for 200 entries
- UI updates: Optimistic, < 100ms
- Memory: < 5MB for typical queue size
