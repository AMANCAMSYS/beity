import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sawa/features/shopping_lists/data/repositories/shopping_list_repository.dart';
import 'package:sawa/features/shopping_lists/data/models/shopping_item_model.dart';
import 'package:sawa/features/shopping_lists/data/models/shopping_list_model.dart';
import 'package:sawa/features/offline_queue/data/repositories/offline_queue_repository.dart';
import 'package:sawa/features/offline_queue/data/repositories/connectivity_repository.dart';
import 'package:sawa/features/offline_queue/data/repositories/offline_aware_shopping_repository.dart';
import 'package:sawa/features/shopping_lists/data/datasources/shopping_local_datasource.dart';
import 'package:sawa/core/services/sync_service.dart';
import 'package:sawa/features/offline_queue/domain/entities/device_sync_status.dart';
import 'package:sawa/features/offline_queue/domain/entities/action_type.dart';
import 'package:sawa/features/offline_queue/domain/entities/entity_type.dart';
import 'package:sawa/features/offline_queue/domain/entities/queue_entry.dart';
import 'package:sawa/features/offline_queue/domain/entities/sync_status.dart';
import 'package:sawa/features/offline_queue/domain/usecases/sync_queue_usecase.dart';

class MockShoppingListRepository extends Mock
    implements ShoppingListRepository {}

class MockConnectivityRepository implements ConnectivityRepository {
  DeviceSyncStatus status = DeviceSyncStatus.online;

  @override
  Future<DeviceSyncStatus> getCurrentStatus() async => status;

  @override
  Stream<DeviceSyncStatus> get statusStream => const Stream.empty();

  @override
  Future<bool> isServerReachable() async => status.isOnline;
}

class MockOfflineQueueRepository implements OfflineQueueRepository {
  final List<QueueEntry> entries = [];
  bool resetCalled = false;
  final List<String> deletedIds = [];
  final List<Map<String, dynamic>> statusUpdates = [];

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
    return entries.where((e) => e.homeId == homeId).toList();
  }

  @override
  Future<void> updateEntryStatus({
    required int entryId,
    required SyncStatus status,
    String? errorMessage,
  }) async {
    statusUpdates.add({
      'entryId': entryId,
      'status': status.name,
      'errorMessage': errorMessage,
    });
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
    deletedIds.add(entryId.toString());
    entries.removeWhere((e) => e.id == entryId);
  }

  @override
  Future<void> resetProcessingToPending(String homeId) async {
    resetCalled = true;
    for (var i = 0; i < entries.length; i++) {
      if (entries[i].homeId == homeId &&
          entries[i].syncStatus == SyncStatus.syncing) {
        entries[i] = entries[i].copyWith(syncStatus: SyncStatus.pending);
      }
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockSyncService extends Mock implements SyncService {}

class MockShoppingLocalDataSource extends Mock
    implements ShoppingLocalDataSource {}

void main() {
  late MockShoppingListRepository mockRemote;
  late MockOfflineQueueRepository mockQueue;
  late MockConnectivityRepository mockConnectivity;
  late MockSyncService mockSyncService;
  late MockShoppingLocalDataSource mockLocalDataSource;
  late OfflineAwareShoppingRepository repository;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://placeholder.supabase.co',
      publishableKey: 'placeholderAnonKey',
    );
    registerFallbackValue(ActionType.addItem);
    registerFallbackValue(EntityType.shoppingItem);
  });

  setUp(() {
    mockRemote = MockShoppingListRepository();
    mockQueue = MockOfflineQueueRepository();
    mockConnectivity = MockConnectivityRepository();
    mockSyncService = MockSyncService();
    mockLocalDataSource = MockShoppingLocalDataSource();

    when(
      () => mockLocalDataSource.getShoppingListsStreamCache(
        homeId: any(named: 'homeId'),
        status: any(named: 'status'),
      ),
    ).thenAnswer((_) async => []);
    when(
      () => mockLocalDataSource.saveShoppingListsStreamCache(
        homeId: any(named: 'homeId'),
        status: any(named: 'status'),
        lists: any(named: 'lists'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockLocalDataSource.getShoppingItemsStreamCache(
        listId: any(named: 'listId'),
      ),
    ).thenAnswer((_) async => []);
    when(
      () => mockLocalDataSource.saveShoppingItemsStreamCache(
        listId: any(named: 'listId'),
        items: any(named: 'items'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockLocalDataSource.getLastLoggedInUserId(),
    ).thenAnswer((_) async => 'user-123');
    when(
      () => mockSyncService.getLocalSyncTimeAsync(any(), any()),
    ).thenAnswer((_) async => DateTime.fromMillisecondsSinceEpoch(0));
    when(
      () => mockSyncService.isInitialSyncDone(any(), any()),
    ).thenAnswer((_) async => false);
    when(
      () => mockSyncService.updateLocalSyncTime(any(), any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => mockRemote.getShoppingLists(
        homeId: any(named: 'homeId'),
        status: any(named: 'status'),
        includeDeleted: any(named: 'includeDeleted'),
      ),
    ).thenAnswer((_) async => []);
    when(
      () => mockRemote.getShoppingItemsForLists(
        listIds: any(named: 'listIds'),
        includeDeleted: any(named: 'includeDeleted'),
      ),
    ).thenAnswer((_) async => <String, List<ShoppingItemModel>>{});

    repository = OfflineAwareShoppingRepository(
      remoteRepository: mockRemote,
      queueRepository: mockQueue,
      connectivityRepository: mockConnectivity,
      localDataSource: mockLocalDataSource,
      syncService: mockSyncService,
      homeId: 'home-123',
    );
  });

  group('T060: Concurrent edit integration test', () {
    test('two users editing same item: last-write-wins on server', () async {
      final baseTime = DateTime(2026, 1, 1, 10, 0, 0);
      final existingItem = ShoppingItemModel(
        id: 'item-shared',
        shoppingListId: 'list-123',
        name: 'Milk',
        quantity: 1,
        createdBy: 'user-A',
        createdAt: baseTime,
        updatedAt: baseTime,
      );

      mockConnectivity.status = DeviceSyncStatus.online;
      when(
        () => mockLocalDataSource.getShoppingListsStreamCache(
          homeId: 'home-123',
          status: any(named: 'status'),
        ),
      ).thenAnswer(
        (_) async => [
          const ShoppingListModel(
            id: 'list-123',
            homeId: 'home-123',
            name: 'Grocery',
            createdBy: 'user-A',
          ),
        ],
      );
      when(
        () =>
            mockLocalDataSource.getShoppingItemsStreamCache(listId: 'list-123'),
      ).thenAnswer((_) async => [existingItem]);

      final userBUpdate = existingItem.copyWithModel(
        name: 'Organic Milk',
        quantity: 2,
        updatedAt: DateTime(2026, 1, 1, 10, 5, 0),
      );
      when(
        () => mockRemote.updateShoppingItem(
          itemId: 'item-shared',
          name: 'Organic Milk',
          quantity: 2,
        ),
      ).thenAnswer((_) async => userBUpdate);

      final result = await repository.updateShoppingItem(
        itemId: 'item-shared',
        name: 'Organic Milk',
        quantity: 2,
      );

      expect(result.name, 'Organic Milk');
      expect(result.quantity, 2);
      verify(
        () => mockRemote.updateShoppingItem(
          itemId: 'item-shared',
          name: 'Organic Milk',
          quantity: 2,
        ),
      ).called(1);
    });

    test('conflict detected when server rejects stale update', () async {
      final baseTime = DateTime(2026, 1, 1, 10, 0, 0);
      mockQueue.entries.add(
        QueueEntry(
          id: 1,
          actionType: ActionType.updateItem,
          entityType: EntityType.shoppingItem,
          entityId: 'item-conflict',
          homeId: 'home-123',
          payload: {
            'name': 'Stale Name',
            'base_updated_at': baseTime.toUtc().toIso8601String(),
          },
          createdAt: DateTime(2026, 1, 1, 10, 1),
          syncStatus: SyncStatus.pending,
        ),
      );

      int executeCallCount = 0;
      Future<String?> fakeExecuteAction(QueueEntry entry) async {
        executeCallCount++;
        throw Exception(
          'conflict: shopping_items/item-conflict changed on server',
        );
      }

      final syncUseCase = SyncQueueUseCase(
        queueRepository: mockQueue,
        connectivityRepository: mockConnectivity,
        executeAction: fakeExecuteAction,
        checkCanSyncNow: () async => true,
        useCompaction: false,
      );

      final result = await syncUseCase.execute('home-123');

      expect(result.successCount, 0);
      expect(result.failedCount, 1);
      expect(result.conflicts, hasLength(1));
      expect(result.conflicts.first.entityId, 'item-conflict');
      expect(result.conflicts.first.errorMessage, contains('conflict'));
      expect(executeCallCount, 1);

      final failedStatus = mockQueue.statusUpdates.firstWhere(
        (u) => u['status'] == 'failed',
      );
      expect(failedStatus['errorMessage'], contains('CONFLICT'));
    });

    test('queue compaction merges multiple updates to same entity', () {
      final entries = [
        QueueEntry(
          id: 1,
          actionType: ActionType.updateItem,
          entityType: EntityType.shoppingItem,
          entityId: 'item-1',
          homeId: 'home-123',
          payload: {'name': 'Milk v2'},
          createdAt: DateTime(2026, 1, 1, 10, 0),
        ),
        QueueEntry(
          id: 2,
          actionType: ActionType.updateItem,
          entityType: EntityType.shoppingItem,
          entityId: 'item-1',
          homeId: 'home-123',
          payload: {'quantity': 3},
          createdAt: DateTime(2026, 1, 1, 10, 1),
        ),
        QueueEntry(
          id: 3,
          actionType: ActionType.updateItem,
          entityType: EntityType.shoppingItem,
          entityId: 'item-1',
          homeId: 'home-123',
          payload: {'note': 'organic'},
          createdAt: DateTime(2026, 1, 1, 10, 2),
        ),
      ];

      final syncUseCase = SyncQueueUseCase(
        queueRepository: mockQueue,
        connectivityRepository: mockConnectivity,
        executeAction: (_) async => null,
      );

      final compacted = syncUseCase.compactQueue(entries);

      expect(compacted, hasLength(1));
      expect(compacted.first.entityId, 'item-1');
      expect(compacted.first.payload['name'], 'Milk v2');
      expect(compacted.first.payload['quantity'], 3);
      expect(compacted.first.payload['note'], 'organic');
    });

    test('queue compaction: create then update merges into single create', () {
      final entries = [
        QueueEntry(
          id: 1,
          actionType: ActionType.addItem,
          entityType: EntityType.shoppingItem,
          entityId: 'local-item-1',
          homeId: 'home-123',
          payload: {'list_id': 'list-123', 'name': 'Milk', 'quantity': 1},
          createdAt: DateTime(2026, 1, 1, 10, 0),
        ),
        QueueEntry(
          id: 2,
          actionType: ActionType.updateItem,
          entityType: EntityType.shoppingItem,
          entityId: 'local-item-1',
          homeId: 'home-123',
          payload: {'quantity': 3, 'note': 'large bottle'},
          createdAt: DateTime(2026, 1, 1, 10, 1),
        ),
      ];

      final syncUseCase = SyncQueueUseCase(
        queueRepository: mockQueue,
        connectivityRepository: mockConnectivity,
        executeAction: (_) async => null,
      );

      final compacted = syncUseCase.compactQueue(entries);

      expect(compacted, hasLength(1));
      expect(compacted.first.actionType, ActionType.addItem);
      expect(compacted.first.payload['name'], 'Milk');
      expect(compacted.first.payload['quantity'], 3);
      expect(compacted.first.payload['note'], 'large bottle');
    });

    test('queue compaction: create then delete discards both', () {
      final entries = [
        QueueEntry(
          id: 1,
          actionType: ActionType.addItem,
          entityType: EntityType.shoppingItem,
          entityId: 'local-item-1',
          homeId: 'home-123',
          payload: {'list_id': 'list-123', 'name': 'Milk'},
          createdAt: DateTime(2026, 1, 1, 10, 0),
        ),
        QueueEntry(
          id: 2,
          actionType: ActionType.deleteItem,
          entityType: EntityType.shoppingItem,
          entityId: 'local-item-1',
          homeId: 'home-123',
          payload: {},
          createdAt: DateTime(2026, 1, 1, 10, 1),
        ),
      ];

      final syncUseCase = SyncQueueUseCase(
        queueRepository: mockQueue,
        connectivityRepository: mockConnectivity,
        executeAction: (_) async => null,
      );

      final compacted = syncUseCase.compactQueue(entries);

      expect(compacted, isEmpty);
    });

    test(
      'last-write-wins: second update overwrites first in compacted queue',
      () {
        final entries = [
          QueueEntry(
            id: 1,
            actionType: ActionType.updateItem,
            entityType: EntityType.shoppingItem,
            entityId: 'item-1',
            homeId: 'home-123',
            payload: {'name': 'First Name'},
            createdAt: DateTime(2026, 1, 1, 10, 0),
          ),
          QueueEntry(
            id: 2,
            actionType: ActionType.updateItem,
            entityType: EntityType.shoppingItem,
            entityId: 'item-1',
            homeId: 'home-123',
            payload: {'name': 'Final Name'},
            createdAt: DateTime(2026, 1, 1, 10, 5),
          ),
        ];

        final syncUseCase = SyncQueueUseCase(
          queueRepository: mockQueue,
          connectivityRepository: mockConnectivity,
          executeAction: (_) async => null,
        );

        final compacted = syncUseCase.compactQueue(entries);

        expect(compacted, hasLength(1));
        expect(compacted.first.payload['name'], 'Final Name');
      },
    );

    test('no data corruption: each entity compacted independently', () {
      final entries = [
        QueueEntry(
          id: 1,
          actionType: ActionType.updateItem,
          entityType: EntityType.shoppingItem,
          entityId: 'item-A',
          homeId: 'home-123',
          payload: {'name': 'Milk Updated'},
          createdAt: DateTime(2026, 1, 1, 10, 0),
        ),
        QueueEntry(
          id: 2,
          actionType: ActionType.updateItem,
          entityType: EntityType.shoppingItem,
          entityId: 'item-B',
          homeId: 'home-123',
          payload: {'name': 'Bread Updated'},
          createdAt: DateTime(2026, 1, 1, 10, 1),
        ),
        QueueEntry(
          id: 3,
          actionType: ActionType.updateItem,
          entityType: EntityType.shoppingItem,
          entityId: 'item-A',
          homeId: 'home-123',
          payload: {'quantity': 5},
          createdAt: DateTime(2026, 1, 1, 10, 2),
        ),
      ];

      final syncUseCase = SyncQueueUseCase(
        queueRepository: mockQueue,
        connectivityRepository: mockConnectivity,
        executeAction: (_) async => null,
      );

      final compacted = syncUseCase.compactQueue(entries);

      expect(compacted, hasLength(2));

      final itemA = compacted.firstWhere((e) => e.entityId == 'item-A');
      final itemB = compacted.firstWhere((e) => e.entityId == 'item-B');

      expect(itemA.payload['name'], 'Milk Updated');
      expect(itemA.payload['quantity'], 5);
      expect(itemB.payload['name'], 'Bread Updated');
      expect(itemB.payload.containsKey('quantity'), isFalse);
    });
  });
}
