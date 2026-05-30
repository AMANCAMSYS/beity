import 'package:flutter_test/flutter_test.dart';
import 'package:beity/features/offline_queue/domain/entities/queue_entry.dart';
import 'package:beity/features/offline_queue/domain/entities/action_type.dart';
import 'package:beity/features/offline_queue/domain/entities/entity_type.dart';
import 'package:beity/features/offline_queue/domain/entities/sync_status.dart';
import 'package:beity/features/offline_queue/domain/entities/device_sync_status.dart';
import 'package:beity/features/offline_queue/data/repositories/offline_queue_repository.dart';
import 'package:beity/features/offline_queue/data/repositories/connectivity_repository.dart';
import 'package:beity/features/offline_queue/domain/usecases/sync_queue_usecase.dart';

void main() {
  group('SyncQueueUseCase Tests', () {
    late FakeOfflineQueueRepository queueRepository;
    late FakeConnectivityRepository connectivityRepository;

    setUp(() {
      queueRepository = FakeOfflineQueueRepository();
      connectivityRepository = FakeConnectivityRepository();
    });

    test('Test 1: Temp ID mapping sequence (Add item -> Update/Toggle/Delete)', () async {
      // 1. Setup the offline entries with temporary UUIDs
      const tempId = 'temp-uuid-123';
      const realId = 'real-supabase-id-999';
      
      final addEntry = QueueEntry(
        id: 1,
        actionType: ActionType.addItem,
        entityType: EntityType.shoppingItem,
        entityId: tempId,
        homeId: 'home-1',
        payload: {'id': tempId, 'list_id': 'list-1', 'name': 'Milk'},
        createdAt: DateTime.now(),
      );

      final updateEntry = QueueEntry(
        id: 2,
        actionType: ActionType.updateItem,
        entityType: EntityType.shoppingItem,
        entityId: tempId,
        homeId: 'home-1',
        payload: {'name': 'Organic Milk', 'quantity': 2.0},
        createdAt: DateTime.now().add(const Duration(seconds: 1)),
      );

      final deleteEntry = QueueEntry(
        id: 3,
        actionType: ActionType.deleteItem,
        entityType: EntityType.shoppingItem,
        entityId: tempId,
        homeId: 'home-1',
        payload: {'itemId': tempId},
        createdAt: DateTime.now().add(const Duration(seconds: 2)),
      );

      queueRepository.entries.addAll([addEntry, updateEntry, deleteEntry]);
      connectivityRepository.status = DeviceSyncStatus.online;

      final List<QueueEntry> executedEntries = [];

      // 2. Initialize the usecase with a mock executor
      final syncUseCase = SyncQueueUseCase(
        queueRepository: queueRepository,
        connectivityRepository: connectivityRepository,
        useCompaction: false,
        executeAction: (entry) async {
          executedEntries.add(entry);
          if (entry.actionType == ActionType.addItem) {
            // Simulate returning the real database-generated ID
            return realId;
          }
          return null;
        },
      );

      // 3. Execute synchronization
      final result = await syncUseCase.execute('home-1');

      // 4. Verification
      expect(result.successCount, 3);
      expect(result.failedCount, 0);
      expect(queueRepository.entries.isEmpty, true, reason: 'Successful entries should be deleted from queue');

      expect(executedEntries.length, 3);
      
      // First action: Add Item
      expect(executedEntries[0].actionType, ActionType.addItem);
      expect(executedEntries[0].entityId, tempId);

      // Second action: Update Item - temp ID replaced by real ID
      expect(executedEntries[1].actionType, ActionType.updateItem);
      expect(executedEntries[1].entityId, realId);
      expect(executedEntries[1].payload['name'], 'Organic Milk');

      // Third action: Delete Item - temp ID replaced by real ID in entityId and payload
      expect(executedEntries[2].actionType, ActionType.deleteItem);
      expect(executedEntries[2].entityId, realId);
      expect(executedEntries[2].payload['itemId'], realId);
    });

    test('Test 2: Failure handling when Supabase fails to return real ID (maybeSingle returns null)', () async {
      // 1. Setup the offline entries
      const tempId = 'temp-uuid-123';
      
      final addEntry = QueueEntry(
        id: 1,
        actionType: ActionType.addItem,
        entityType: EntityType.shoppingItem,
        entityId: tempId,
        homeId: 'home-1',
        payload: {'id': tempId, 'list_id': 'list-1', 'name': 'Milk'},
        createdAt: DateTime.now(),
      );

      final updateEntry = QueueEntry(
        id: 2,
        actionType: ActionType.updateItem,
        entityType: EntityType.shoppingItem,
        entityId: tempId,
        homeId: 'home-1',
        payload: {'name': 'Organic Milk'},
        createdAt: DateTime.now().add(const Duration(seconds: 1)),
      );

      queueRepository.entries.addAll([addEntry, updateEntry]);
      connectivityRepository.status = DeviceSyncStatus.online;

      // 2. Initialize usecase where executeAction returns null for addItem,
      // and throws an exception on updateItem because the ID is invalid or missing.
      final syncUseCase = SyncQueueUseCase(
        queueRepository: queueRepository,
        connectivityRepository: connectivityRepository,
        useCompaction: false,
        executeAction: (entry) async {
          if (entry.actionType == ActionType.addItem) {
            // Supabase successfully inserted but maybeSingle() returned null (or no ID selected)
            return null; 
          }
          if (entry.actionType == ActionType.updateItem) {
            // Throw exception because mapping failed, simulating server error (entity not found)
            throw Exception('PostgrestException: 404 Not Found - Entity not found');
          }
          return null;
        },
      );

      // 3. Execute synchronization
      final result = await syncUseCase.execute('home-1');

      // 4. Verification
      expect(result.successCount, 1);
      expect(result.failedCount, 1);
      
      // The successful addItem should be deleted
      // The failed updateItem should remain in the queue with a failed status
      expect(queueRepository.entries.length, 1);
      expect(queueRepository.entries.first.id, 2);
      expect(queueRepository.entries.first.syncStatus, SyncStatus.failed);
      expect(queueRepository.entries.first.errorMessage, contains('Entity not found'));
    });

    test('Test 3: Compaction - Create + Delete offline should discard both', () async {
      final now = DateTime.now();
      final addEntry = QueueEntry(
        id: 1,
        actionType: ActionType.addItem,
        entityType: EntityType.shoppingItem,
        entityId: 'item-1',
        homeId: 'home-1',
        payload: {'name': 'Milk'},
        createdAt: now,
      );

      final deleteEntry = QueueEntry(
        id: 2,
        actionType: ActionType.deleteItem,
        entityType: EntityType.shoppingItem,
        entityId: 'item-1',
        homeId: 'home-1',
        payload: {},
        createdAt: now.add(const Duration(seconds: 1)),
      );

      queueRepository.entries.addAll([addEntry, deleteEntry]);
      connectivityRepository.status = DeviceSyncStatus.online;

      final syncUseCase = SyncQueueUseCase(
        queueRepository: queueRepository,
        connectivityRepository: connectivityRepository,
        executeAction: (entry) async => null,
      );

      final result = await syncUseCase.execute('home-1');

      // Compaction should discard both, so 0 success, 0 failure
      expect(result.successCount, 0);
      expect(result.failedCount, 0);
    });

    test('Test 4: Compaction - Update + Delete for existing item should compact to delete only', () async {
      final now = DateTime.now();
      final updateEntry = QueueEntry(
        id: 1,
        actionType: ActionType.updateItem,
        entityType: EntityType.shoppingItem,
        entityId: 'item-1',
        homeId: 'home-1',
        payload: {'name': 'New Milk'},
        createdAt: now,
      );

      final deleteEntry = QueueEntry(
        id: 2,
        actionType: ActionType.deleteItem,
        entityType: EntityType.shoppingItem,
        entityId: 'item-1',
        homeId: 'home-1',
        payload: {},
        createdAt: now.add(const Duration(seconds: 1)),
      );

      queueRepository.entries.addAll([updateEntry, deleteEntry]);
      connectivityRepository.status = DeviceSyncStatus.online;

      final List<QueueEntry> executedEntries = [];
      final syncUseCase = SyncQueueUseCase(
        queueRepository: queueRepository,
        connectivityRepository: connectivityRepository,
        executeAction: (entry) async {
          executedEntries.add(entry);
          return null;
        },
      );

      final result = await syncUseCase.execute('home-1');

      expect(result.successCount, 1);
      expect(executedEntries.length, 1);
      expect(executedEntries.first.actionType, ActionType.deleteItem);
    });

    test('Test 5: Compaction - Create + Update should merge into single Create', () async {
      final now = DateTime.now();
      final addEntry = QueueEntry(
        id: 1,
        actionType: ActionType.addItem,
        entityType: EntityType.shoppingItem,
        entityId: 'item-1',
        homeId: 'home-1',
        payload: {'name': 'Milk', 'quantity': 1},
        createdAt: now,
      );

      final updateEntry = QueueEntry(
        id: 2,
        actionType: ActionType.updateItem,
        entityType: EntityType.shoppingItem,
        entityId: 'item-1',
        homeId: 'home-1',
        payload: {'quantity': 3, 'note': 'Get organic'},
        createdAt: now.add(const Duration(seconds: 1)),
      );

      queueRepository.entries.addAll([addEntry, updateEntry]);
      connectivityRepository.status = DeviceSyncStatus.online;

      final List<QueueEntry> executedEntries = [];
      final syncUseCase = SyncQueueUseCase(
        queueRepository: queueRepository,
        connectivityRepository: connectivityRepository,
        executeAction: (entry) async {
          executedEntries.add(entry);
          return null;
        },
      );

      final result = await syncUseCase.execute('home-1');

      expect(result.successCount, 1);
      expect(executedEntries.length, 1);
      expect(executedEntries.first.actionType, ActionType.addItem);
      expect(executedEntries.first.payload['name'], 'Milk');
      expect(executedEntries.first.payload['quantity'], 3);
      expect(executedEntries.first.payload['note'], 'Get organic');
    });

    test('Test 6: Locking - Parallel execution is gated', () async {
      connectivityRepository.status = DeviceSyncStatus.online;
      
      final entry = QueueEntry(
        id: 1,
        actionType: ActionType.addItem,
        entityType: EntityType.shoppingItem,
        entityId: 'item-1',
        homeId: 'home-1',
        payload: {'name': 'Milk'},
        createdAt: DateTime.now(),
      );
      queueRepository.entries.add(entry);

      final syncUseCase = SyncQueueUseCase(
        queueRepository: queueRepository,
        connectivityRepository: connectivityRepository,
        executeAction: (e) async {
          // Add a delay to hold the lock
          await Future.delayed(const Duration(milliseconds: 100));
          return null;
        },
      );

      // Trigger first execution (will hold the lock)
      final Future<SyncResult> firstRun = syncUseCase.execute('home-1');
      
      // Trigger second execution immediately (should be blocked by lock)
      final SyncResult secondResult = await syncUseCase.execute('home-1');

      final firstResult = await firstRun;

      expect(firstResult.successCount, 1);
      expect(secondResult.successCount, 0);
      expect(secondResult.failedCount, 0);
    });

    test('Test 7: Crash Recovery - Resets syncing status to pending before run', () async {
      final entry = QueueEntry(
        id: 1,
        actionType: ActionType.addItem,
        entityType: EntityType.shoppingItem,
        entityId: 'item-1',
        homeId: 'home-1',
        payload: {'name': 'Milk'},
        createdAt: DateTime.now(),
        syncStatus: SyncStatus.syncing, // stuck in syncing state
      );
      queueRepository.entries.add(entry);
      connectivityRepository.status = DeviceSyncStatus.online;

      final syncUseCase = SyncQueueUseCase(
        queueRepository: queueRepository,
        connectivityRepository: connectivityRepository,
        executeAction: (e) async => null,
      );

      final result = await syncUseCase.execute('home-1');

      // The stuck entry should be recovered to pending and successfully synced!
      expect(result.successCount, 1);
      expect(queueRepository.entries.isEmpty, true);
    });

    test('Test 8: Smart Retry - Permanent vs Temporary Errors', () async {
      final entryPerm = QueueEntry(
        id: 1,
        actionType: ActionType.addItem,
        entityType: EntityType.shoppingItem,
        entityId: 'item-1',
        homeId: 'home-1',
        payload: {'name': 'Permanent Fail Item'},
        createdAt: DateTime.now(),
      );

      final entryTemp = QueueEntry(
        id: 2,
        actionType: ActionType.addItem,
        entityType: EntityType.shoppingItem,
        entityId: 'item-2',
        homeId: 'home-1',
        payload: {'name': 'Temporary Fail Item'},
        createdAt: DateTime.now().add(const Duration(seconds: 1)),
      );

      queueRepository.entries.addAll([entryPerm, entryTemp]);
      connectivityRepository.status = DeviceSyncStatus.online;

      final syncUseCase = SyncQueueUseCase(
        queueRepository: queueRepository,
        connectivityRepository: connectivityRepository,
        executeAction: (entry) async {
          if (entry.entityId == 'item-1') {
            throw Exception('PostgrestException: 400 Bad Request - Column not found');
          } else {
            throw Exception('SocketException: Connection timed out');
          }
        },
      );

      final result = await syncUseCase.execute('home-1');

      expect(result.successCount, 0);
      expect(result.failedCount, 2);

      // Verify statuses stored in repository
      final recoveredPerm = queueRepository.entries.firstWhere((e) => e.id == 1);
      final recoveredTemp = queueRepository.entries.firstWhere((e) => e.id == 2);

      // Permanent error gets marked with PERMANENT prefix
      expect(recoveredPerm.errorMessage, contains('PERMANENT'));
      expect(recoveredPerm.syncStatus, SyncStatus.failed);

      // Temporary error gets stored normally
      expect(recoveredTemp.errorMessage, contains('SocketException'));
      expect(recoveredTemp.syncStatus, SyncStatus.failed);
    });
  });
}

// FAKE IMPLEMENTATIONS FOR TESTING

class FakeOfflineQueueRepository implements OfflineQueueRepository {
  final List<QueueEntry> entries = [];

  @override
  Future<void> enqueueAction({
    required ActionType actionType,
    required EntityType entityType,
    required String entityId,
    required String homeId,
    required Map<String, dynamic> payload,
  }) async {
    entries.add(QueueEntry(
      id: entries.length + 1,
      actionType: actionType,
      entityType: entityType,
      entityId: entityId,
      homeId: homeId,
      payload: payload,
      createdAt: DateTime.now(),
    ));
  }

  @override
  Future<List<QueueEntry>> getEntriesByHome(String homeId) async {
    return entries.where((e) => e.homeId == homeId).toList();
  }

  @override
  Future<List<QueueEntry>> getEntriesByStatus(SyncStatus status) async {
    return entries.where((e) => e.syncStatus == status).toList();
  }

  @override
  Future<int> getPendingCount(String homeId) async {
    return entries.where((e) => e.homeId == homeId && e.isPending).length;
  }

  @override
  Future<QueueEntry?> getEntryById(int id) async {
    return entries.firstWhere((e) => e.id == id);
  }

  @override
  Future<void> updateEntryStatus({
    required int entryId,
    required SyncStatus status,
    String? errorMessage,
  }) async {
    final index = entries.indexWhere((e) => e.id == entryId);
    if (index != -1) {
      entries[index] = entries[index].copyWith(
        syncStatus: status,
        errorMessage: errorMessage,
      );
    }
  }

  @override
  Future<void> deleteEntry(int entryId) async {
    entries.removeWhere((e) => e.id == entryId);
  }

  @override
  Future<void> deleteCompletedEntries(String homeId) async {
    // Fakes deletion of completed entries
  }

  @override
  Future<List<QueueEntry>> getFailedEntries(String homeId) async {
    return entries.where((e) => e.homeId == homeId && e.isFailed).toList();
  }

  @override
  Future<void> resetProcessingToPending(String homeId) async {
    for (int i = 0; i < entries.length; i++) {
      if (entries[i].homeId == homeId && entries[i].syncStatus == SyncStatus.syncing) {
        entries[i] = entries[i].copyWith(syncStatus: SyncStatus.pending);
      }
    }
  }
}

class FakeConnectivityRepository implements ConnectivityRepository {
  DeviceSyncStatus status = DeviceSyncStatus.online;

  @override
  Future<DeviceSyncStatus> getCurrentStatus() async => status;

  @override
  Stream<DeviceSyncStatus> get statusStream => Stream.value(status);

  @override
  Future<bool> isServerReachable() async => status.isOnline;
}
