import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/features/offline_queue/domain/entities/queue_entry.dart';
import 'package:sawa/features/offline_queue/domain/entities/action_type.dart';
import 'package:sawa/features/offline_queue/domain/entities/entity_type.dart';
import 'package:sawa/features/offline_queue/domain/entities/sync_status.dart';
import 'package:sawa/features/offline_queue/data/repositories/offline_queue_repository.dart';

void main() {
  group('Account Switching Isolation Tests', () {
    late FakeOfflineQueueRepository queueRepository;

    setUp(() {
      queueRepository = FakeOfflineQueueRepository();
    });

    // ============================================================
    // 1. USER DATA ISOLATION
    // ============================================================
    group('User Data Isolation', () {
      test('queue entries should be scoped by user/home', () async {
        // User A adds items
        queueRepository.entries.addAll([
          QueueEntry(
            id: 1,
            actionType: ActionType.addItem,
            entityType: EntityType.shoppingItem,
            entityId: 'item-a1',
            homeId: 'home-user-a',
            payload: {'name': 'User A Item'},
            createdAt: DateTime.now(),
          ),
          QueueEntry(
            id: 2,
            actionType: ActionType.addItem,
            entityType: EntityType.shoppingItem,
            entityId: 'item-a2',
            homeId: 'home-user-a',
            payload: {'name': 'User A Item 2'},
            createdAt: DateTime.now(),
          ),
        ]);

        // User B has different home
        queueRepository.entries.add(
          QueueEntry(
            id: 3,
            actionType: ActionType.addItem,
            entityType: EntityType.shoppingItem,
            entityId: 'item-b1',
            homeId: 'home-user-b',
            payload: {'name': 'User B Item'},
            createdAt: DateTime.now(),
          ),
        );

        final userAEntries = await queueRepository.getEntriesByHome(
          'home-user-a',
        );
        final userBEntries = await queueRepository.getEntriesByHome(
          'home-user-b',
        );

        expect(userAEntries.length, 2);
        expect(userBEntries.length, 1);
        expect(userAEntries.every((e) => e.homeId == 'home-user-a'), true);
        expect(userBEntries.every((e) => e.homeId == 'home-user-b'), true);
      });

      test('clearing queue for user should only affect that user', () async {
        queueRepository.entries.addAll([
          QueueEntry(
            id: 1,
            actionType: ActionType.addItem,
            entityType: EntityType.shoppingItem,
            entityId: 'item-a1',
            homeId: 'home-user-a',
            payload: {'name': 'User A Item'},
            createdAt: DateTime.now(),
          ),
          QueueEntry(
            id: 2,
            actionType: ActionType.addItem,
            entityType: EntityType.shoppingItem,
            entityId: 'item-b1',
            homeId: 'home-user-b',
            payload: {'name': 'User B Item'},
            createdAt: DateTime.now(),
          ),
        ]);

        // Clear only user A's entries
        await queueRepository.clearForHome('home-user-a');

        final userAEntries = await queueRepository.getEntriesByHome(
          'home-user-a',
        );
        final userBEntries = await queueRepository.getEntriesByHome(
          'home-user-b',
        );

        expect(userAEntries.isEmpty, true);
        expect(userBEntries.length, 1);
      });
    });

    // ============================================================
    // 2. LOGOUT BEHAVIOR
    // ============================================================
    group('Logout Behavior', () {
      test('logout should clear all queue entries for the user', () async {
        queueRepository.entries.addAll([
          QueueEntry(
            id: 1,
            actionType: ActionType.addItem,
            entityType: EntityType.shoppingItem,
            entityId: 'item-1',
            homeId: 'home-1',
            payload: {'name': 'Pending Item 1'},
            createdAt: DateTime.now(),
          ),
          QueueEntry(
            id: 2,
            actionType: ActionType.updateItem,
            entityType: EntityType.shoppingItem,
            entityId: 'item-2',
            homeId: 'home-1',
            payload: {'name': 'Updated Item'},
            createdAt: DateTime.now(),
          ),
          QueueEntry(
            id: 3,
            actionType: ActionType.deleteItem,
            entityType: EntityType.shoppingItem,
            entityId: 'item-3',
            homeId: 'home-1',
            payload: {},
            createdAt: DateTime.now(),
          ),
        ]);

        expect(queueRepository.entries.length, 3);

        // Simulate logout clearing
        await queueRepository.clearForHome('home-1');

        expect(queueRepository.entries.isEmpty, true);
      });

      test(
        'logout while sync is in progress should not corrupt queue',
        () async {
          queueRepository.entries.addAll([
            QueueEntry(
              id: 1,
              actionType: ActionType.addItem,
              entityType: EntityType.shoppingItem,
              entityId: 'item-1',
              homeId: 'home-1',
              payload: {'name': 'Milk'},
              createdAt: DateTime.now(),
              syncStatus: SyncStatus.syncing,
            ),
            QueueEntry(
              id: 2,
              actionType: ActionType.addItem,
              entityType: EntityType.shoppingItem,
              entityId: 'item-2',
              homeId: 'home-1',
              payload: {'name': 'Bread'},
              createdAt: DateTime.now(),
              syncStatus: SyncStatus.pending,
            ),
          ]);

          // Reset stuck syncing entries before logout
          await queueRepository.resetProcessingToPending('home-1');

          // Verify all entries are pending now
          expect(
            queueRepository.entries.every(
              (e) => e.syncStatus == SyncStatus.pending,
            ),
            true,
          );

          // Then clear
          await queueRepository.clearForHome('home-1');
          expect(queueRepository.entries.isEmpty, true);
        },
      );
    });

    // ============================================================
    // 3. LOGIN BEHAVIOR
    // ============================================================
    group('Login Behavior', () {
      test('new login should start with empty queue', () async {
        // Previous user had entries
        queueRepository.entries.addAll([
          QueueEntry(
            id: 1,
            actionType: ActionType.addItem,
            entityType: EntityType.shoppingItem,
            entityId: 'old-item',
            homeId: 'old-home',
            payload: {'name': 'Old Item'},
            createdAt: DateTime.now(),
          ),
        ]);

        // Simulate logout clearing
        await queueRepository.clearForHome('old-home');
        expect(queueRepository.entries.isEmpty, true);

        // New user should have empty queue
        final newEntries = await queueRepository.getEntriesByHome('new-home');
        expect(newEntries.isEmpty, true);
      });

      test(
        'switching accounts should not leak queue entries between users',
        () async {
          // User A session
          queueRepository.entries.add(
            QueueEntry(
              id: 1,
              actionType: ActionType.addItem,
              entityType: EntityType.shoppingItem,
              entityId: 'item-a',
              homeId: 'home-a',
              payload: {'name': 'User A pending'},
              createdAt: DateTime.now(),
            ),
          );

          // Logout user A
          await queueRepository.clearForHome('home-a');

          // Login user B
          queueRepository.entries.add(
            QueueEntry(
              id: 2,
              actionType: ActionType.addItem,
              entityType: EntityType.shoppingItem,
              entityId: 'item-b',
              homeId: 'home-b',
              payload: {'name': 'User B pending'},
              createdAt: DateTime.now(),
            ),
          );

          final userAEntries = await queueRepository.getEntriesByHome('home-a');
          final userBEntries = await queueRepository.getEntriesByHome('home-b');

          expect(userAEntries.isEmpty, true);
          expect(userBEntries.length, 1);
          expect(userBEntries.first.entityId, 'item-b');
        },
      );
    });

    // ============================================================
    // 4. QUEUE PERSISTENCE ACROSS SESSIONS
    // ============================================================
    group('Queue Persistence', () {
      test('pending entries should survive app restart simulation', () async {
        // Simulate app session 1: add items offline
        queueRepository.entries.addAll([
          QueueEntry(
            id: 1,
            actionType: ActionType.addItem,
            entityType: EntityType.shoppingItem,
            entityId: 'item-1',
            homeId: 'home-1',
            payload: {'name': 'Milk'},
            createdAt: DateTime.now(),
            syncStatus: SyncStatus.pending,
          ),
          QueueEntry(
            id: 2,
            actionType: ActionType.addItem,
            entityType: EntityType.shoppingItem,
            entityId: 'item-2',
            homeId: 'home-1',
            payload: {'name': 'Bread'},
            createdAt: DateTime.now(),
            syncStatus: SyncStatus.pending,
          ),
        ]);

        // Simulate app restart: entries should still be there
        final entries = await queueRepository.getEntriesByHome('home-1');
        expect(entries.length, 2);

        // Verify all are pending
        expect(entries.every((e) => e.syncStatus == SyncStatus.pending), true);
      });

      test('failed entries should persist across sessions for retry', () async {
        queueRepository.entries.addAll([
          QueueEntry(
            id: 1,
            actionType: ActionType.addItem,
            entityType: EntityType.shoppingItem,
            entityId: 'item-1',
            homeId: 'home-1',
            payload: {'name': 'Milk'},
            createdAt: DateTime.now(),
            syncStatus: SyncStatus.failed,
            retryCount: 2,
            errorMessage: 'SocketException: Timeout',
          ),
          QueueEntry(
            id: 2,
            actionType: ActionType.addItem,
            entityType: EntityType.shoppingItem,
            entityId: 'item-2',
            homeId: 'home-1',
            payload: {'name': 'Bread'},
            createdAt: DateTime.now(),
            syncStatus: SyncStatus.failed,
            retryCount: 1,
            errorMessage: 'PERMANENT: 400 Bad Request',
          ),
        ]);

        final failedEntries = await queueRepository.getFailedEntries('home-1');
        expect(failedEntries.length, 2);

        // Check temporary vs permanent classification
        final tempFailures = failedEntries
            .where((e) => !(e.errorMessage?.startsWith('PERMANENT') ?? false))
            .toList();
        final permFailures = failedEntries
            .where((e) => e.errorMessage?.startsWith('PERMANENT') ?? false)
            .toList();

        expect(tempFailures.length, 1);
        expect(permFailures.length, 1);
      });
    });
  });
}

class FakeOfflineQueueRepository implements OfflineQueueRepository {
  final List<QueueEntry> entries = [];

  @override
  Future<void> enqueueAction({
    required ActionType actionType,
    required EntityType entityType,
    required String entityId,
    String? homeId,
    MutationScope scope = MutationScope.home,
    required Map<String, dynamic> payload,
  }) async {
    entries.add(
      QueueEntry(
        id: entries.length + 1,
        actionType: actionType,
        entityType: entityType,
        entityId: entityId,
        homeId: homeId,
        scope: scope,
        payload: payload,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<List<QueueEntry>> getEntriesByHome(String homeId) async {
    return entries
        .where((e) => e.homeId == homeId && e.scope == MutationScope.home)
        .toList();
  }

  @override
  Future<List<QueueEntry>> getEntriesByStatus(SyncStatus status) async {
    return entries.where((e) => e.syncStatus == status).toList();
  }

  @override
  Future<int> getPendingCount(String homeId) async {
    return entries
        .where(
          (e) =>
              e.homeId == homeId &&
              e.scope == MutationScope.home &&
              e.isPending,
        )
        .length;
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
  Future<void> deleteCompletedEntries(String homeId) async {}

  @override
  Future<List<QueueEntry>> getFailedEntries(String homeId) async {
    return entries
        .where(
          (e) =>
              e.homeId == homeId && e.scope == MutationScope.home && e.isFailed,
        )
        .toList();
  }

  @override
  Future<void> resetProcessingToPending(String homeId) async {
    for (int i = 0; i < entries.length; i++) {
      if (entries[i].homeId == homeId &&
          entries[i].scope == MutationScope.home &&
          entries[i].syncStatus == SyncStatus.syncing) {
        entries[i] = entries[i].copyWith(syncStatus: SyncStatus.pending);
      }
    }
  }

  @override
  Future<List<QueueEntry>> getEntriesByUserScope(String userId) async {
    return entries
        .where((e) => e.scope == MutationScope.user && _isSyncableStatus(e))
        .toList();
  }

  @override
  Future<List<QueueEntry>> getEntriesByGlobalScope() async {
    return entries
        .where((e) => e.scope == MutationScope.global && _isSyncableStatus(e))
        .toList();
  }

  @override
  Future<int> getPendingCountForUser(String userId) async {
    return entries
        .where(
          (e) =>
              e.isPending &&
              (e.scope == MutationScope.user ||
                  e.scope == MutationScope.global),
        )
        .length;
  }

  @override
  Future<void> resetProcessingToPendingForUserScope(String userId) async {
    for (int i = 0; i < entries.length; i++) {
      final isUserScoped =
          entries[i].scope == MutationScope.user ||
          entries[i].scope == MutationScope.global;
      if (isUserScoped && entries[i].syncStatus == SyncStatus.syncing) {
        entries[i] = entries[i].copyWith(syncStatus: SyncStatus.pending);
      }
    }
  }

  bool _isSyncableStatus(QueueEntry entry) {
    return entry.isPending || entry.isSyncing || entry.isFailed;
  }

  Future<void> clearForHome(String homeId) async {
    entries.removeWhere((e) => e.homeId == homeId);
  }
}
