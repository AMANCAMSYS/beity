import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/features/offline_queue/domain/entities/queue_entry.dart';
import 'package:sawa/features/offline_queue/domain/entities/action_type.dart';
import 'package:sawa/features/offline_queue/domain/entities/entity_type.dart';
import 'package:sawa/features/offline_queue/domain/entities/sync_status.dart';
import 'package:sawa/features/offline_queue/domain/entities/device_sync_status.dart';
import 'package:sawa/features/offline_queue/data/repositories/offline_queue_repository.dart';
import 'package:sawa/features/offline_queue/data/repositories/connectivity_repository.dart';
import 'package:sawa/features/offline_queue/domain/usecases/sync_queue_usecase.dart';

void main() {
  group('Offline Queue Critical Tests', () {
    late FakeOfflineQueueRepository queueRepository;
    late FakeConnectivityRepository connectivityRepository;

    setUp(() {
      queueRepository = FakeOfflineQueueRepository();
      connectivityRepository = FakeConnectivityRepository();
    });

    // ============================================================
    // 1. OFFLINE ADD BUG - Item created offline appears then disappears
    // ============================================================
    group('Offline Add Bug', () {
      test(
        'item added offline should persist in queue until sync succeeds',
        () async {
          connectivityRepository.status = DeviceSyncStatus.offline;

          final entry = QueueEntry(
            id: 1,
            actionType: ActionType.addItem,
            entityType: EntityType.shoppingItem,
            entityId: 'temp-uuid-1',
            homeId: 'home-1',
            payload: {
              'id': 'temp-uuid-1',
              'list_id': 'list-1',
              'name': 'Milk',
              'quantity': 1,
            },
            createdAt: DateTime.now(),
          );
          queueRepository.entries.add(entry);

          // Queue should have the entry
          expect(queueRepository.entries.length, 1);
          expect(queueRepository.entries.first.entityId, 'temp-uuid-1');
          expect(queueRepository.entries.first.actionType, ActionType.addItem);

          // Simulate coming back online
          connectivityRepository.status = DeviceSyncStatus.online;

          final syncUseCase = SyncQueueUseCase(
            queueRepository: queueRepository,
            connectivityRepository: connectivityRepository,
            useCompaction: false,
            executeAction: (entry) async => 'real-id-1',
          );

          final result = await syncUseCase.execute('home-1');

          expect(result.successCount, 1);
          expect(result.failedCount, 0);
          expect(queueRepository.entries.isEmpty, true);
        },
      );

      test(
        'multiple offline adds should all be synced without data loss',
        () async {
          connectivityRepository.status = DeviceSyncStatus.offline;

          for (int i = 1; i <= 5; i++) {
            queueRepository.entries.add(
              QueueEntry(
                id: i,
                actionType: ActionType.addItem,
                entityType: EntityType.shoppingItem,
                entityId: 'temp-uuid-$i',
                homeId: 'home-1',
                payload: {
                  'id': 'temp-uuid-$i',
                  'list_id': 'list-1',
                  'name': 'Item $i',
                },
                createdAt: DateTime.now().add(Duration(seconds: i)),
              ),
            );
          }

          expect(queueRepository.entries.length, 5);

          connectivityRepository.status = DeviceSyncStatus.online;

          final syncUseCase = SyncQueueUseCase(
            queueRepository: queueRepository,
            connectivityRepository: connectivityRepository,
            useCompaction: false,
            executeAction: (entry) async => 'real-${entry.entityId}',
          );

          final result = await syncUseCase.execute('home-1');

          expect(result.successCount, 5);
          expect(queueRepository.entries.isEmpty, true);
        },
      );

      test(
        'offline add then immediate update should compact to single create',
        () async {
          final now = DateTime.now();

          queueRepository.entries.addAll([
            QueueEntry(
              id: 1,
              actionType: ActionType.addItem,
              entityType: EntityType.shoppingItem,
              entityId: 'temp-uuid-1',
              homeId: 'home-1',
              payload: {
                'id': 'temp-uuid-1',
                'list_id': 'list-1',
                'name': 'Milk',
                'quantity': 1,
              },
              createdAt: now,
            ),
            QueueEntry(
              id: 2,
              actionType: ActionType.updateItem,
              entityType: EntityType.shoppingItem,
              entityId: 'temp-uuid-1',
              homeId: 'home-1',
              payload: {'name': 'Organic Milk', 'quantity': 2},
              createdAt: now.add(const Duration(seconds: 1)),
            ),
          ]);

          connectivityRepository.status = DeviceSyncStatus.online;

          final List<QueueEntry> executedEntries = [];
          final syncUseCase = SyncQueueUseCase(
            queueRepository: queueRepository,
            connectivityRepository: connectivityRepository,
            executeAction: (entry) async {
              executedEntries.add(entry);
              return 'real-id-1';
            },
          );

          final result = await syncUseCase.execute('home-1');

          // Should compact to single create
          expect(result.successCount, 1);
          expect(executedEntries.length, 1);
          expect(executedEntries.first.actionType, ActionType.addItem);
          // Merged payload
          expect(executedEntries.first.payload['name'], 'Organic Milk');
          expect(executedEntries.first.payload['quantity'], 2);
        },
      );
    });

    // ============================================================
    // 2. QUEUE RECOVERY - Stuck entries should be recovered
    // ============================================================
    group('Queue Recovery', () {
      test(
        'stuck syncing entries should be reset to pending before sync',
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
              syncStatus: SyncStatus.syncing, // stuck!
            ),
            QueueEntry(
              id: 2,
              actionType: ActionType.addItem,
              entityType: EntityType.shoppingItem,
              entityId: 'item-2',
              homeId: 'home-1',
              payload: {'name': 'Bread'},
              createdAt: DateTime.now().add(const Duration(seconds: 1)),
              syncStatus: SyncStatus.syncing, // stuck!
            ),
          ]);
          connectivityRepository.status = DeviceSyncStatus.online;

          final syncUseCase = SyncQueueUseCase(
            queueRepository: queueRepository,
            connectivityRepository: connectivityRepository,
            executeAction: (entry) async => null,
          );

          final result = await syncUseCase.execute('home-1');

          expect(result.successCount, 2);
          expect(queueRepository.entries.isEmpty, true);
        },
      );

      test('failed temporary entries should be retried on next sync', () async {
        queueRepository.entries.add(
          QueueEntry(
            id: 1,
            actionType: ActionType.addItem,
            entityType: EntityType.shoppingItem,
            entityId: 'item-1',
            homeId: 'home-1',
            payload: {'name': 'Milk'},
            createdAt: DateTime.now(),
            syncStatus: SyncStatus.failed,
            retryCount: 1,
            errorMessage: 'SocketException: Connection timed out',
          ),
        );
        connectivityRepository.status = DeviceSyncStatus.online;

        final syncUseCase = SyncQueueUseCase(
          queueRepository: queueRepository,
          connectivityRepository: connectivityRepository,
          executeAction: (entry) async => 'real-id-1',
        );

        final result = await syncUseCase.execute('home-1');

        expect(result.successCount, 1);
        expect(queueRepository.entries.isEmpty, true);
      });

      test('permanent failed entries should NOT be retried', () async {
        queueRepository.entries.add(
          QueueEntry(
            id: 1,
            actionType: ActionType.addItem,
            entityType: EntityType.shoppingItem,
            entityId: 'item-1',
            homeId: 'home-1',
            payload: {'name': 'Milk'},
            createdAt: DateTime.now(),
            syncStatus: SyncStatus.failed,
            retryCount: 1,
            errorMessage: 'PERMANENT: 400 Bad Request',
          ),
        );
        connectivityRepository.status = DeviceSyncStatus.online;

        final syncUseCase = SyncQueueUseCase(
          queueRepository: queueRepository,
          connectivityRepository: connectivityRepository,
          executeAction: (entry) async => null,
        );

        final result = await syncUseCase.execute('home-1');

        // Permanent errors should be skipped
        expect(result.successCount, 0);
        expect(result.failedCount, 0);
        expect(queueRepository.entries.length, 1);
      });

      test('max retries exceeded entries should not be retried', () async {
        queueRepository.entries.add(
          QueueEntry(
            id: 1,
            actionType: ActionType.addItem,
            entityType: EntityType.shoppingItem,
            entityId: 'item-1',
            homeId: 'home-1',
            payload: {'name': 'Milk'},
            createdAt: DateTime.now(),
            syncStatus: SyncStatus.failed,
            retryCount: QueueEntry.maxRetries + 1,
            errorMessage: 'SocketException: Connection timed out',
          ),
        );
        connectivityRepository.status = DeviceSyncStatus.online;

        final syncUseCase = SyncQueueUseCase(
          queueRepository: queueRepository,
          connectivityRepository: connectivityRepository,
          executeAction: (entry) async => null,
        );

        final result = await syncUseCase.execute('home-1');

        expect(result.successCount, 0);
        expect(queueRepository.entries.length, 1);
      });
    });

    // ============================================================
    // 3. RACE CONDITIONS - Parallel sync should be prevented
    // ============================================================
    group('Race Conditions', () {
      test('concurrent sync for same home should be blocked by lock', () async {
        connectivityRepository.status = DeviceSyncStatus.online;

        queueRepository.entries.add(
          QueueEntry(
            id: 1,
            actionType: ActionType.addItem,
            entityType: EntityType.shoppingItem,
            entityId: 'item-1',
            homeId: 'home-1',
            payload: {'name': 'Milk'},
            createdAt: DateTime.now(),
          ),
        );

        int executionCount = 0;
        final syncUseCase = SyncQueueUseCase(
          queueRepository: queueRepository,
          connectivityRepository: connectivityRepository,
          executeAction: (entry) async {
            executionCount++;
            await Future.delayed(const Duration(milliseconds: 100));
            return null;
          },
        );

        // Start two syncs simultaneously
        final firstRun = syncUseCase.execute('home-1');
        final secondResult = await syncUseCase.execute('home-1');
        final firstResult = await firstRun;

        expect(firstResult.successCount, 1);
        expect(secondResult.successCount, 0);
        expect(executionCount, 1);
      });

      test('sync for different homes should run in parallel', () async {
        connectivityRepository.status = DeviceSyncStatus.online;

        queueRepository.entries.addAll([
          QueueEntry(
            id: 1,
            actionType: ActionType.addItem,
            entityType: EntityType.shoppingItem,
            entityId: 'item-1',
            homeId: 'home-1',
            payload: {'name': 'Milk'},
            createdAt: DateTime.now(),
          ),
          QueueEntry(
            id: 2,
            actionType: ActionType.addItem,
            entityType: EntityType.shoppingItem,
            entityId: 'item-2',
            homeId: 'home-2',
            payload: {'name': 'Bread'},
            createdAt: DateTime.now(),
          ),
        ]);

        final sharedLock = SyncQueueLock();
        final syncUseCase = SyncQueueUseCase(
          queueRepository: queueRepository,
          connectivityRepository: connectivityRepository,
          syncLock: sharedLock,
          executeAction: (entry) async {
            if (entry.homeId == 'home-1') {
              await Future.delayed(const Duration(milliseconds: 100));
            }
            return null;
          },
        );

        final firstRun = syncUseCase.execute('home-1');
        final secondResult = await syncUseCase.execute('home-2');
        final firstResult = await firstRun;

        expect(firstResult.successCount, 1);
        expect(secondResult.successCount, 1);
      });

      test('lock is released even if sync throws an exception', () async {
        connectivityRepository.status = DeviceSyncStatus.online;

        queueRepository.entries.add(
          QueueEntry(
            id: 1,
            actionType: ActionType.addItem,
            entityType: EntityType.shoppingItem,
            entityId: 'item-1',
            homeId: 'home-1',
            payload: {'name': 'Milk'},
            createdAt: DateTime.now(),
          ),
        );

        final sharedLock = SyncQueueLock();
        bool shouldFail = true;

        final syncUseCase = SyncQueueUseCase(
          queueRepository: queueRepository,
          connectivityRepository: connectivityRepository,
          syncLock: sharedLock,
          useCompaction: false,
          executeAction: (entry) async {
            if (shouldFail) {
              shouldFail = false;
              throw Exception('Server error');
            }
            return null;
          },
        );

        // First sync fails
        final result1 = await syncUseCase.execute('home-1');
        expect(result1.failedCount, 1);

        // Lock should be released - verify by attempting another sync
        // The failed entry (retryCount=1) is still retryable, so second sync should process it
        final result2 = await syncUseCase.execute('home-1');
        // The previously failed entry should now succeed
        expect(result2.successCount, 1);
      });
    });

    // ============================================================
    // 4. CONFLICT HANDLING
    // ============================================================
    group('Conflict Handling', () {
      test(
        '409 conflict should be detected and kept as failed conflict',
        () async {
          queueRepository.entries.add(
            QueueEntry(
              id: 1,
              actionType: ActionType.updateItem,
              entityType: EntityType.shoppingItem,
              entityId: 'item-1',
              homeId: 'home-1',
              payload: {'name': 'Updated Milk'},
              createdAt: DateTime.now(),
            ),
          );
          connectivityRepository.status = DeviceSyncStatus.online;

          final syncUseCase = SyncQueueUseCase(
            queueRepository: queueRepository,
            connectivityRepository: connectivityRepository,
            executeAction: (entry) async {
              throw Exception('409 Conflict - stale data');
            },
          );

          final result = await syncUseCase.execute('home-1');

          expect(result.successCount, 0);
          expect(result.failedCount, 1);
          expect(result.conflicts.length, 1);
          expect(result.conflicts.first.entityId, 'item-1');
          expect(queueRepository.entries.length, 1);
          expect(queueRepository.entries.first.syncStatus, SyncStatus.failed);
          expect(
            queueRepository.entries.first.errorMessage,
            startsWith('CONFLICT:'),
          );
        },
      );

      test('temporary error should keep entry in queue for retry', () async {
        queueRepository.entries.add(
          QueueEntry(
            id: 1,
            actionType: ActionType.addItem,
            entityType: EntityType.shoppingItem,
            entityId: 'item-1',
            homeId: 'home-1',
            payload: {'name': 'Milk'},
            createdAt: DateTime.now(),
          ),
        );
        connectivityRepository.status = DeviceSyncStatus.online;

        final syncUseCase = SyncQueueUseCase(
          queueRepository: queueRepository,
          connectivityRepository: connectivityRepository,
          executeAction: (entry) async {
            throw Exception('SocketException: Connection timed out');
          },
        );

        final result = await syncUseCase.execute('home-1');

        expect(result.successCount, 0);
        expect(result.failedCount, 1);
        expect(queueRepository.entries.length, 1);
        expect(queueRepository.entries.first.syncStatus, SyncStatus.failed);
        expect(
          queueRepository.entries.first.errorMessage,
          contains('SocketException'),
        );
      });

      test('permanent error (401) should be marked as PERMANENT', () async {
        queueRepository.entries.add(
          QueueEntry(
            id: 1,
            actionType: ActionType.addItem,
            entityType: EntityType.shoppingItem,
            entityId: 'item-1',
            homeId: 'home-1',
            payload: {'name': 'Milk'},
            createdAt: DateTime.now(),
          ),
        );
        connectivityRepository.status = DeviceSyncStatus.online;

        final syncUseCase = SyncQueueUseCase(
          queueRepository: queueRepository,
          connectivityRepository: connectivityRepository,
          executeAction: (entry) async {
            throw Exception('401 Unauthorized');
          },
        );

        final result = await syncUseCase.execute('home-1');

        expect(result.failedCount, 1);
        expect(
          queueRepository.entries.first.errorMessage,
          contains('PERMANENT'),
        );
      });

      test(
        'permanent error (403 forbidden) should be marked as PERMANENT',
        () async {
          queueRepository.entries.add(
            QueueEntry(
              id: 1,
              actionType: ActionType.addItem,
              entityType: EntityType.shoppingItem,
              entityId: 'item-1',
              homeId: 'home-1',
              payload: {'name': 'Milk'},
              createdAt: DateTime.now(),
            ),
          );
          connectivityRepository.status = DeviceSyncStatus.online;

          final syncUseCase = SyncQueueUseCase(
            queueRepository: queueRepository,
            connectivityRepository: connectivityRepository,
            executeAction: (entry) async {
              throw Exception('403 Forbidden - permission denied');
            },
          );

          final result = await syncUseCase.execute('home-1');

          expect(result.failedCount, 1);
          expect(
            queueRepository.entries.first.errorMessage,
            contains('PERMANENT'),
          );
        },
      );

      test('validation error (422) should be marked as PERMANENT', () async {
        queueRepository.entries.add(
          QueueEntry(
            id: 1,
            actionType: ActionType.addItem,
            entityType: EntityType.shoppingItem,
            entityId: 'item-1',
            homeId: 'home-1',
            payload: {'name': ''},
            createdAt: DateTime.now(),
          ),
        );
        connectivityRepository.status = DeviceSyncStatus.online;

        final syncUseCase = SyncQueueUseCase(
          queueRepository: queueRepository,
          connectivityRepository: connectivityRepository,
          executeAction: (entry) async {
            throw Exception('422 Unprocessable Entity - validation failed');
          },
        );

        final result = await syncUseCase.execute('home-1');

        expect(result.failedCount, 1);
        expect(
          queueRepository.entries.first.errorMessage,
          contains('PERMANENT'),
        );
      });
    });

    // ============================================================
    // 5. QUEUE COMPACTION EDGE CASES
    // ============================================================
    group('Queue Compaction Edge Cases', () {
      test('create + delete + create should keep the second create', () async {
        final now = DateTime.now();
        queueRepository.entries.addAll([
          QueueEntry(
            id: 1,
            actionType: ActionType.addItem,
            entityType: EntityType.shoppingItem,
            entityId: 'item-1',
            homeId: 'home-1',
            payload: {'name': 'First Milk'},
            createdAt: now,
          ),
          QueueEntry(
            id: 2,
            actionType: ActionType.deleteItem,
            entityType: EntityType.shoppingItem,
            entityId: 'item-1',
            homeId: 'home-1',
            payload: {},
            createdAt: now.add(const Duration(seconds: 1)),
          ),
          QueueEntry(
            id: 3,
            actionType: ActionType.addItem,
            entityType: EntityType.shoppingItem,
            entityId: 'item-1',
            homeId: 'home-1',
            payload: {'name': 'Second Milk'},
            createdAt: now.add(const Duration(seconds: 2)),
          ),
        ]);
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

        // create+delete = discard, then the second create remains
        expect(result.successCount, 1);
        expect(executedEntries.length, 1);
        expect(executedEntries.first.actionType, ActionType.addItem);
        expect(executedEntries.first.payload['name'], 'Second Milk');
      });

      test(
        'multiple updates should compact to single update with merged payload',
        () async {
          final now = DateTime.now();
          queueRepository.entries.addAll([
            QueueEntry(
              id: 1,
              actionType: ActionType.updateItem,
              entityType: EntityType.shoppingItem,
              entityId: 'item-1',
              homeId: 'home-1',
              payload: {'name': 'New Milk'},
              createdAt: now,
            ),
            QueueEntry(
              id: 2,
              actionType: ActionType.updateQuantity,
              entityType: EntityType.shoppingItem,
              entityId: 'item-1',
              homeId: 'home-1',
              payload: {'quantity': 3.0},
              createdAt: now.add(const Duration(seconds: 1)),
            ),
            QueueEntry(
              id: 3,
              actionType: ActionType.markPurchased,
              entityType: EntityType.shoppingItem,
              entityId: 'item-1',
              homeId: 'home-1',
              payload: {
                'status': 'completed',
                'completed_at': '2026-01-01T00:00:00Z',
              },
              createdAt: now.add(const Duration(seconds: 2)),
            ),
          ]);
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
          // When markPurchased is combined with other updates, it becomes updateItem
          expect(executedEntries.first.actionType, ActionType.updateItem);
          expect(executedEntries.first.payload['name'], 'New Milk');
          expect(executedEntries.first.payload['quantity'], 3.0);
          expect(executedEntries.first.payload['status'], 'completed');
        },
      );

      test(
        'markPurchased only (status toggle) should remain as markPurchased',
        () async {
          final now = DateTime.now();
          queueRepository.entries.addAll([
            QueueEntry(
              id: 1,
              actionType: ActionType.markPurchased,
              entityType: EntityType.shoppingItem,
              entityId: 'item-1',
              homeId: 'home-1',
              payload: {
                'status': 'completed',
                'completed_at': '2026-01-01T00:00:00Z',
              },
              createdAt: now,
            ),
            QueueEntry(
              id: 2,
              actionType: ActionType.markPurchased,
              entityType: EntityType.shoppingItem,
              entityId: 'item-1',
              homeId: 'home-1',
              payload: {'status': 'pending', 'completed_at': null},
              createdAt: now.add(const Duration(seconds: 1)),
            ),
          ]);
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
          // When only status/completed_at fields, stays as markPurchased
          expect(executedEntries.first.actionType, ActionType.markPurchased);
        },
      );

      test(
        'markPurchased with purchased_quantity should become updateItem',
        () async {
          final now = DateTime.now();
          queueRepository.entries.addAll([
            QueueEntry(
              id: 1,
              actionType: ActionType.markPurchased,
              entityType: EntityType.shoppingItem,
              entityId: 'item-1',
              homeId: 'home-1',
              payload: {
                'status': 'completed',
                'completed_at': '2026-01-01T00:00:00Z',
              },
              createdAt: now,
            ),
            QueueEntry(
              id: 2,
              actionType: ActionType.markPurchased,
              entityType: EntityType.shoppingItem,
              entityId: 'item-1',
              homeId: 'home-1',
              payload: {
                'status': 'pending',
                'completed_at': null,
                'purchased_quantity': 0.0,
              },
              createdAt: now.add(const Duration(seconds: 1)),
            ),
          ]);
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
          // purchased_quantity is an "other update", so becomes updateItem
          expect(executedEntries.first.actionType, ActionType.updateItem);
        },
      );

      test(
        'compaction preserves chronological order across entities',
        () async {
          final now = DateTime.now();
          queueRepository.entries.addAll([
            QueueEntry(
              id: 1,
              actionType: ActionType.addItem,
              entityType: EntityType.shoppingItem,
              entityId: 'item-a',
              homeId: 'home-1',
              payload: {'name': 'Item A'},
              createdAt: now,
            ),
            QueueEntry(
              id: 2,
              actionType: ActionType.addItem,
              entityType: EntityType.shoppingItem,
              entityId: 'item-b',
              homeId: 'home-1',
              payload: {'name': 'Item B'},
              createdAt: now.add(const Duration(seconds: 1)),
            ),
            QueueEntry(
              id: 3,
              actionType: ActionType.updateItem,
              entityType: EntityType.shoppingItem,
              entityId: 'item-a',
              homeId: 'home-1',
              payload: {'name': 'Updated A'},
              createdAt: now.add(const Duration(seconds: 2)),
            ),
          ]);
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

          // item-a: add+update -> compacted to single add
          // item-b: add (unchanged)
          expect(result.successCount, 2);
          expect(executedEntries.length, 2);

          // Should be in chronological order
          expect(executedEntries[0].entityId, 'item-a');
          expect(executedEntries[0].actionType, ActionType.addItem);
          expect(executedEntries[0].payload['name'], 'Updated A');
          expect(executedEntries[1].entityId, 'item-b');
          expect(executedEntries[1].actionType, ActionType.addItem);
        },
      );
    });

    // ============================================================
    // 6. TEMP ID MAPPING
    // ============================================================
    group('Temp ID Mapping', () {
      test(
        'temp ID should be replaced in subsequent entries after add succeeds',
        () async {
          const tempId = 'temp-uuid-123';
          const realId = 'real-db-id-999';

          queueRepository.entries.addAll([
            QueueEntry(
              id: 1,
              actionType: ActionType.addItem,
              entityType: EntityType.shoppingItem,
              entityId: tempId,
              homeId: 'home-1',
              payload: {'id': tempId, 'list_id': 'list-1', 'name': 'Milk'},
              createdAt: DateTime.now(),
            ),
            QueueEntry(
              id: 2,
              actionType: ActionType.updateItem,
              entityType: EntityType.shoppingItem,
              entityId: tempId,
              homeId: 'home-1',
              payload: {'name': 'Organic Milk'},
              createdAt: DateTime.now().add(const Duration(seconds: 1)),
            ),
            QueueEntry(
              id: 3,
              actionType: ActionType.deleteItem,
              entityType: EntityType.shoppingItem,
              entityId: tempId,
              homeId: 'home-1',
              payload: {'itemId': tempId},
              createdAt: DateTime.now().add(const Duration(seconds: 2)),
            ),
          ]);
          connectivityRepository.status = DeviceSyncStatus.online;

          final List<QueueEntry> executedEntries = [];
          final syncUseCase = SyncQueueUseCase(
            queueRepository: queueRepository,
            connectivityRepository: connectivityRepository,
            useCompaction: false,
            executeAction: (entry) async {
              executedEntries.add(entry);
              if (entry.actionType == ActionType.addItem) return realId;
              return null;
            },
          );

          final result = await syncUseCase.execute('home-1');

          expect(result.successCount, 3);

          // First: add with temp ID
          expect(executedEntries[0].entityId, tempId);

          // Second: update with real ID
          expect(executedEntries[1].entityId, realId);

          // Third: delete with real ID (both entityId and payload)
          expect(executedEntries[2].entityId, realId);
          expect(executedEntries[2].payload['itemId'], realId);
        },
      );

      test(
        'temp ID mapping should work across different entity types',
        () async {
          const tempListId = 'temp-list-uuid';
          const realListId = 'real-list-id';
          const tempItemId = 'temp-item-uuid';
          const realItemId = 'real-item-id';

          queueRepository.entries.addAll([
            QueueEntry(
              id: 1,
              actionType: ActionType.addItem,
              entityType: EntityType.shoppingList,
              entityId: tempListId,
              homeId: 'home-1',
              payload: {'id': tempListId, 'name': 'Grocery'},
              createdAt: DateTime.now(),
            ),
            QueueEntry(
              id: 2,
              actionType: ActionType.addItem,
              entityType: EntityType.shoppingItem,
              entityId: tempItemId,
              homeId: 'home-1',
              payload: {
                'id': tempItemId,
                'list_id': tempListId,
                'name': 'Milk',
              },
              createdAt: DateTime.now().add(const Duration(seconds: 1)),
            ),
          ]);
          connectivityRepository.status = DeviceSyncStatus.online;

          final List<QueueEntry> executedEntries = [];
          final syncUseCase = SyncQueueUseCase(
            queueRepository: queueRepository,
            connectivityRepository: connectivityRepository,
            useCompaction: false,
            executeAction: (entry) async {
              executedEntries.add(entry);
              if (entry.entityId == tempListId) return realListId;
              if (entry.entityId == tempItemId) return realItemId;
              return null;
            },
          );

          final result = await syncUseCase.execute('home-1');

          expect(result.successCount, 2);

          // Second entry should have the list_id updated to real ID
          expect(executedEntries[1].payload['list_id'], realListId);
        },
      );
    });

    // ============================================================
    // 7. OFFLINE -> ONLINE TRANSITION
    // ============================================================
    group('Offline to Online Transition', () {
      test('sync should abort when offline', () async {
        queueRepository.entries.add(
          QueueEntry(
            id: 1,
            actionType: ActionType.addItem,
            entityType: EntityType.shoppingItem,
            entityId: 'item-1',
            homeId: 'home-1',
            payload: {'name': 'Milk'},
            createdAt: DateTime.now(),
          ),
        );
        connectivityRepository.status = DeviceSyncStatus.offline;

        final syncUseCase = SyncQueueUseCase(
          queueRepository: queueRepository,
          connectivityRepository: connectivityRepository,
          executeAction: (entry) async => null,
        );

        final result = await syncUseCase.execute('home-1');

        expect(result.successCount, 0);
        expect(result.failedCount, 0);
        // Entry should still be in queue
        expect(queueRepository.entries.length, 1);
      });

      test('sync should proceed when online', () async {
        queueRepository.entries.add(
          QueueEntry(
            id: 1,
            actionType: ActionType.addItem,
            entityType: EntityType.shoppingItem,
            entityId: 'item-1',
            homeId: 'home-1',
            payload: {'name': 'Milk'},
            createdAt: DateTime.now(),
          ),
        );
        connectivityRepository.status = DeviceSyncStatus.online;

        final syncUseCase = SyncQueueUseCase(
          queueRepository: queueRepository,
          connectivityRepository: connectivityRepository,
          executeAction: (entry) async => 'real-id',
        );

        final result = await syncUseCase.execute('home-1');

        expect(result.successCount, 1);
        expect(queueRepository.entries.isEmpty, true);
      });

      test('checkCanSyncNow callback should be respected', () async {
        queueRepository.entries.add(
          QueueEntry(
            id: 1,
            actionType: ActionType.addItem,
            entityType: EntityType.shoppingItem,
            entityId: 'item-1',
            homeId: 'home-1',
            payload: {'name': 'Milk'},
            createdAt: DateTime.now(),
          ),
        );

        final syncUseCase = SyncQueueUseCase(
          queueRepository: queueRepository,
          connectivityRepository: connectivityRepository,
          checkCanSyncNow: () async => false, // WiFi-only mode blocking
          executeAction: (entry) async => null,
        );

        final result = await syncUseCase.execute('home-1');

        expect(result.successCount, 0);
        expect(queueRepository.entries.length, 1);
      });
    });

    // ============================================================
    // 8. EMPTY QUEUE
    // ============================================================
    group('Empty Queue', () {
      test('sync on empty queue should return zero counts', () async {
        connectivityRepository.status = DeviceSyncStatus.online;

        final syncUseCase = SyncQueueUseCase(
          queueRepository: queueRepository,
          connectivityRepository: connectivityRepository,
          executeAction: (entry) async => null,
        );

        final result = await syncUseCase.execute('home-1');

        expect(result.successCount, 0);
        expect(result.failedCount, 0);
        expect(result.conflicts.isEmpty, true);
        expect(result.hasResults, false);
      });
    });
  });
}

// FAKE IMPLEMENTATIONS

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
