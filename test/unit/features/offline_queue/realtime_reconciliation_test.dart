import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/features/shopping_lists/data/models/shopping_item_model.dart';
import 'package:sawa/features/shopping_lists/data/models/shopping_list_model.dart';
import 'package:sawa/features/offline_queue/domain/entities/queue_entry.dart';
import 'package:sawa/features/offline_queue/domain/entities/action_type.dart';
import 'package:sawa/features/offline_queue/domain/entities/entity_type.dart';
import 'package:sawa/features/offline_queue/data/repositories/offline_queue_repository.dart';
import 'package:sawa/features/offline_queue/data/repositories/connectivity_repository.dart';
import 'package:sawa/features/offline_queue/data/repositories/offline_aware_shopping_repository.dart';
import 'package:sawa/features/shopping_lists/data/repositories/shopping_list_repository.dart';
import 'package:sawa/features/shopping_lists/data/datasources/shopping_local_datasource.dart';
import 'package:sawa/core/services/sync_service.dart';
import 'package:sawa/features/offline_queue/domain/entities/device_sync_status.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockShoppingListRepository extends Mock
    implements ShoppingListRepository {}

class MockOfflineQueueRepository extends Mock
    implements OfflineQueueRepository {}

class MockConnectivityRepository extends Mock
    implements ConnectivityRepository {}

class MockSyncService extends Mock implements SyncService {}

class MockShoppingLocalDataSource extends Mock
    implements ShoppingLocalDataSource {}

void main() {
  group('Realtime Reconciliation Tests', () {
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
        () =>
            mockLocalDataSource.getItemTemplates(homeId: any(named: 'homeId')),
      ).thenAnswer((_) async => []);
      when(
        () => mockLocalDataSource.saveItemTemplates(
          homeId: any(named: 'homeId'),
          templates: any(named: 'templates'),
        ),
      ).thenAnswer((_) async {});
      when(() => mockQueue.getEntriesByHome(any())).thenAnswer((_) async => []);
      when(
        () => mockQueue.enqueueAction(
          actionType: any(named: 'actionType'),
          entityType: any(named: 'entityType'),
          entityId: any(named: 'entityId'),
          homeId: any(named: 'homeId'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});
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

    // ============================================================
    // 1. EMPTY STATE SYNC
    // ============================================================
    group('Empty State Sync', () {
      test(
        'should sync empty server state on first sync even if local cache is empty',
        () async {
          when(
            () => mockSyncService.getServerLastUpdates('home-123'),
          ).thenAnswer(
            (_) async => {
              'shopping_lists': DateTime.fromMillisecondsSinceEpoch(0),
              'shopping_items': DateTime.fromMillisecondsSinceEpoch(0),
            },
          );
          when(
            () => mockSyncService.getLocalSyncTime('home-123', any()),
          ).thenReturn(DateTime.fromMillisecondsSinceEpoch(0));
          when(
            () => mockSyncService.updateLocalSyncTime('home-123', any(), any()),
          ).thenAnswer((_) async {});
          when(
            () => mockRemote.getShoppingLists(homeId: 'home-123'),
          ).thenAnswer((_) async => []);
          when(
            () => mockRemote.getItemTemplates(homeId: 'home-123'),
          ).thenAnswer((_) async => []);

          await repository.syncShoppingWithServer('home-123');

          verify(
            () => mockLocalDataSource.saveShoppingListsStreamCache(
              homeId: 'home-123',
              status: any(named: 'status'),
              lists: any(named: 'lists'),
            ),
          ).called(greaterThanOrEqualTo(1));
        },
      );

      test('should NOT refetch after empty state was already synced', () async {
        final syncTimes = <String, DateTime>{};
        final syncedDomains = <String>{};

        when(() => mockSyncService.getServerLastUpdates('home-123')).thenAnswer(
          (_) async => {
            'shopping_lists': DateTime.fromMillisecondsSinceEpoch(0),
            'shopping_items': DateTime.fromMillisecondsSinceEpoch(0),
          },
        );
        when(
          () => mockSyncService.getLocalSyncTimeAsync('home-123', any()),
        ).thenAnswer((invocation) async {
          final domain = invocation.positionalArguments[1] as String;
          return syncTimes[domain] ?? DateTime.fromMillisecondsSinceEpoch(0);
        });
        when(
          () => mockSyncService.isInitialSyncDone('home-123', any()),
        ).thenAnswer((invocation) async {
          final domain = invocation.positionalArguments[1] as String;
          return syncedDomains.contains(domain);
        });
        when(
          () => mockSyncService.updateLocalSyncTime('home-123', any(), any()),
        ).thenAnswer((invocation) async {
          final domain = invocation.positionalArguments[1] as String;
          final time = invocation.positionalArguments[2] as DateTime;
          syncTimes[domain] = time;
          syncedDomains.add(domain);
        });
        when(
          () => mockRemote.getShoppingLists(homeId: 'home-123'),
        ).thenAnswer((_) async => []);
        when(
          () => mockRemote.getItemTemplates(homeId: 'home-123'),
        ).thenAnswer((_) async => []);

        await repository.syncShoppingWithServer('home-123');
        await repository.syncShoppingWithServer('home-123');

        verify(
          () => mockRemote.getShoppingLists(
            homeId: 'home-123',
            status: any(named: 'status'),
            includeDeleted: true,
          ),
        ).called(1);
      });
    });

    // ============================================================
    // 2. BATCH QUERY
    // ============================================================
    group('Batch Query Optimization', () {
      test('should fetch items for all lists in one batch query', () async {
        final lists = List.generate(
          5,
          (i) => ShoppingListModel(
            id: 'list-$i',
            homeId: 'home-123',
            name: 'List $i',
            createdBy: 'user-123',
          ),
        );

        when(() => mockSyncService.getServerLastUpdates('home-123')).thenAnswer(
          (_) async => {
            'shopping_lists': DateTime.fromMillisecondsSinceEpoch(0),
            'shopping_items': DateTime(2026, 1, 2),
          },
        );
        when(
          () => mockSyncService.getLocalSyncTime('home-123', any()),
        ).thenReturn(DateTime.fromMillisecondsSinceEpoch(0));
        when(
          () => mockSyncService.updateLocalSyncTime('home-123', any(), any()),
        ).thenAnswer((_) async {});
        when(
          () => mockLocalDataSource.getShoppingListsStreamCache(
            homeId: 'home-123',
            status: any(named: 'status'),
          ),
        ).thenAnswer((_) async => lists);
        when(
          () => mockRemote.getShoppingItemsForLists(
            listIds: any(named: 'listIds'),
            includeDeleted: any(named: 'includeDeleted'),
          ),
        ).thenAnswer(
          (_) async => {
            for (final list in lists) list.id: <ShoppingItemModel>[],
          },
        );
        when(
          () => mockRemote.getItemTemplates(homeId: 'home-123'),
        ).thenAnswer((_) async => []);

        await repository.syncShoppingWithServer('home-123');

        final capturedListIds =
            verify(
                  () => mockRemote.getShoppingItemsForLists(
                    listIds: captureAny(named: 'listIds'),
                    includeDeleted: true,
                  ),
                ).captured.single
                as List<String>;

        expect(capturedListIds, hasLength(5));
        verifyNever(
          () => mockRemote.getShoppingItems(listId: any(named: 'listId')),
        );
      });
    });

    // ============================================================
    // 3. QUEUE MERGE WITH SERVER
    // ============================================================
    group('Queue Merge with Server', () {
      test(
        'pending local item should be preserved when server returns empty',
        () async {
          const list = ShoppingListModel(
            id: 'list-1',
            homeId: 'home-123',
            name: 'Grocery',
            createdBy: 'user-123',
          );
          const localPendingItem = ShoppingItemModel(
            id: 'local-item-1',
            shoppingListId: 'list-1',
            name: 'Local Milk',
            quantity: 2,
            createdBy: 'user-123',
          );

          when(
            () => mockSyncService.getServerLastUpdates('home-123'),
          ).thenAnswer(
            (_) async => {
              'shopping_lists': DateTime.fromMillisecondsSinceEpoch(0),
              'shopping_items': DateTime(2026, 1, 2),
            },
          );
          when(
            () => mockSyncService.getLocalSyncTime('home-123', any()),
          ).thenReturn(DateTime.fromMillisecondsSinceEpoch(0));
          when(
            () => mockSyncService.updateLocalSyncTime('home-123', any(), any()),
          ).thenAnswer((_) async {});
          when(
            () => mockLocalDataSource.getShoppingListsStreamCache(
              homeId: 'home-123',
              status: any(named: 'status'),
            ),
          ).thenAnswer((_) async => [list]);
          when(
            () => mockLocalDataSource.getShoppingItemsStreamCache(
              listId: 'list-1',
            ),
          ).thenAnswer((_) async => [localPendingItem]);
          when(
            () => mockRemote.getShoppingItemsForLists(
              listIds: any(named: 'listIds'),
            ),
          ).thenAnswer((_) async => {'list-1': <ShoppingItemModel>[]});
          when(
            () => mockRemote.getItemTemplates(homeId: 'home-123'),
          ).thenAnswer((_) async => []);
          when(() => mockQueue.getEntriesByHome('home-123')).thenAnswer(
            (_) async => [
              QueueEntry(
                id: 1,
                actionType: ActionType.addItem,
                entityType: EntityType.shoppingItem,
                entityId: localPendingItem.id,
                homeId: 'home-123',
                payload: localPendingItem.toJson(),
                createdAt: DateTime(2026, 1, 1),
              ),
            ],
          );

          await repository.syncShoppingWithServer('home-123');

          final captured =
              verify(
                    () => mockLocalDataSource.saveShoppingItemsStreamCache(
                      listId: 'list-1',
                      items: captureAny(named: 'items'),
                    ),
                  ).captured.last
                  as List<ShoppingItemModel>;

          expect(captured.map((item) => item.id), contains('local-item-1'));
          expect(captured.single.name, 'Local Milk');
        },
      );
    });

    // ============================================================
    // 4. OPTIMISTIC UPDATE ROLLBACK
    // ============================================================
    group('Optimistic Update Rollback', () {
      test(
        'deleteShoppingItem should enqueue for retry on remote failure',
        () async {
          when(
            () => mockConnectivity.getCurrentStatus(),
          ).thenAnswer((_) async => DeviceSyncStatus.online);

          when(
            () => mockLocalDataSource.getShoppingListsStreamCache(
              homeId: 'home-123',
              status: any(named: 'status'),
            ),
          ).thenAnswer(
            (_) async => [
              const ShoppingListModel(
                id: 'list-1',
                homeId: 'home-123',
                name: 'Grocery',
                createdBy: 'user-123',
              ),
            ],
          );
          when(
            () => mockLocalDataSource.getShoppingItemsStreamCache(
              listId: 'list-1',
            ),
          ).thenAnswer((_) async => []);
          when(
            () => mockLocalDataSource.saveShoppingItemsStreamCache(
              listId: any(named: 'listId'),
              items: any(named: 'items'),
            ),
          ).thenAnswer((_) async {});

          when(
            () => mockRemote.deleteShoppingItem(itemId: 'item-1'),
          ).thenThrow(Exception('Server error'));

          when(
            () => mockQueue.enqueueAction(
              actionType: any(named: 'actionType'),
              entityType: any(named: 'entityType'),
              entityId: any(named: 'entityId'),
              homeId: any(named: 'homeId'),
              payload: any(named: 'payload'),
            ),
          ).thenAnswer((_) async {});

          await repository.deleteShoppingItem(itemId: 'item-1');

          // Should enqueue delete action for retry
          verify(
            () => mockQueue.enqueueAction(
              actionType: ActionType.deleteItem,
              entityType: EntityType.shoppingItem,
              entityId: 'item-1',
              homeId: 'home-123',
              payload: any(named: 'payload'),
            ),
          ).called(1);
        },
      );
    });

    // ============================================================
    // 5. DELETE REQUIRES ONLINE
    // ============================================================
    group('Delete Offline', () {
      test('deleteShoppingList should enqueue when offline', () async {
        when(
          () => mockConnectivity.getCurrentStatus(),
        ).thenAnswer((_) async => DeviceSyncStatus.offline);

        await repository.deleteShoppingList(listId: 'list-1');

        verify(
          () => mockQueue.enqueueAction(
            actionType: ActionType.deleteItem,
            entityType: EntityType.shoppingList,
            entityId: 'list-1',
            homeId: 'home-123',
            payload: any(named: 'payload'),
          ),
        ).called(1);
      });
    });

    // ============================================================
    // 6. LOCAL-FIRST READS
    // ============================================================
    group('Local-First Reads', () {
      test(
        'getShoppingLists should return cached lists without hitting remote',
        () async {
          final cachedLists = [
            const ShoppingListModel(
              id: 'list-1',
              homeId: 'home-123',
              name: 'Cached List',
              createdBy: 'user-123',
            ),
          ];

          when(
            () => mockLocalDataSource.getShoppingListsStreamCache(
              homeId: 'home-123',
              status: null,
            ),
          ).thenAnswer((_) async => cachedLists);

          final result = await repository.getShoppingLists(homeId: 'home-123');

          expect(result, cachedLists);
          verifyNever(
            () => mockRemote.getShoppingLists(homeId: any(named: 'homeId')),
          );
        },
      );

      test(
        'getShoppingItems should return cached items without hitting remote',
        () async {
          final cachedItems = [
            const ShoppingItemModel(
              id: 'item-1',
              shoppingListId: 'list-1',
              name: 'Cached Item',
              quantity: 1,
              createdBy: 'user-123',
            ),
          ];

          when(
            () => mockLocalDataSource.getShoppingItemsStreamCache(
              listId: 'list-1',
            ),
          ).thenAnswer((_) async => cachedItems);

          final result = await repository.getShoppingItems(listId: 'list-1');

          expect(result, cachedItems);
          verifyNever(
            () => mockRemote.getShoppingItems(listId: any(named: 'listId')),
          );
        },
      );

      test(
        'getShoppingLists should fallback to remote when cache is empty',
        () async {
          final serverLists = [
            const ShoppingListModel(
              id: 'list-1',
              homeId: 'home-123',
              name: 'Server List',
              createdBy: 'user-123',
            ),
          ];

          when(
            () => mockLocalDataSource.getShoppingListsStreamCache(
              homeId: 'home-123',
              status: null,
            ),
          ).thenAnswer((_) async => []);
          when(
            () => mockRemote.getShoppingLists(homeId: 'home-123'),
          ).thenAnswer((_) async => serverLists);

          final result = await repository.getShoppingLists(homeId: 'home-123');

          expect(result, serverLists);
          verify(
            () => mockRemote.getShoppingLists(homeId: 'home-123'),
          ).called(1);
        },
      );
    });
  });
}
