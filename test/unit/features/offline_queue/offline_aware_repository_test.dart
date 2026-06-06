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
  late MockShoppingListRepository mockRemote;
  late MockOfflineQueueRepository mockQueue;
  late MockConnectivityRepository mockConnectivity;
  late MockSyncService mockSyncService;
  late MockShoppingLocalDataSource mockLocalDataSource;
  late OfflineAwareShoppingRepository repository;

  setUp(() {
    mockRemote = MockShoppingListRepository();
    mockQueue = MockOfflineQueueRepository();
    mockConnectivity = MockConnectivityRepository();
    mockSyncService = MockSyncService();
    mockLocalDataSource = MockShoppingLocalDataSource();

    // Setup stub values for local data source so getters return empty lists instead of throwing
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
    ).thenAnswer((_) async => 'anonymous');
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

  // Register fallback values for mocktail
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

  group('createShoppingItem', () {
    const tItem = ShoppingItemModel(
      id: 'item-123',
      shoppingListId: 'list-123',
      name: 'Milk',
      quantity: 1,
      createdBy: 'user-123',
    );

    test('should call remote repository when online', () async {
      when(
        () => mockConnectivity.getCurrentStatus(),
      ).thenAnswer((_) async => DeviceSyncStatus.online);
      when(
        () => mockRemote.createShoppingItem(
          id: any(named: 'id'),
          listId: any(named: 'listId'),
          name: any(named: 'name'),
          quantity: any(named: 'quantity'),
          unitId: any(named: 'unitId'),
          categoryId: any(named: 'categoryId'),
          price: any(named: 'price'),
          currency: any(named: 'currency'),
          notes: any(named: 'notes'),
        ),
      ).thenAnswer((_) async => tItem);

      final result = await repository.createShoppingItem(
        listId: 'list-123',
        name: 'Milk',
      );

      expect(result.name, 'Milk');
      verify(
        () => mockRemote.createShoppingItem(
          id: any(named: 'id'),
          listId: 'list-123',
          name: 'Milk',
        ),
      ).called(1);
      verifyNever(
        () => mockQueue.enqueueAction(
          actionType: any(named: 'actionType'),
          entityType: any(named: 'entityType'),
          entityId: any(named: 'entityId'),
          homeId: any(named: 'homeId'),
          payload: any(named: 'payload'),
        ),
      );
    });

    test('should queue action when offline', () async {
      when(
        () => mockConnectivity.getCurrentStatus(),
      ).thenAnswer((_) async => DeviceSyncStatus.offline);
      when(
        () => mockQueue.enqueueAction(
          actionType: any(named: 'actionType'),
          entityType: any(named: 'entityType'),
          entityId: any(named: 'entityId'),
          homeId: any(named: 'homeId'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});

      final result = await repository.createShoppingItem(
        listId: 'list-123',
        name: 'Milk',
      );

      // Returns optimistic model
      expect(result.name, 'Milk');
      verify(
        () => mockQueue.enqueueAction(
          actionType: ActionType.addItem,
          entityType: EntityType.shoppingItem,
          entityId: any(named: 'entityId'),
          homeId: 'home-123',
          payload: any(named: 'payload'),
        ),
      ).called(1);
      verifyNever(
        () => mockRemote.createShoppingItem(
          id: any(named: 'id'),
          listId: any(named: 'listId'),
          name: any(named: 'name'),
        ),
      );
    });

    test('throws loudly instead of queuing item without a homeId', () async {
      final repositoryWithoutHomeId = OfflineAwareShoppingRepository(
        remoteRepository: mockRemote,
        queueRepository: mockQueue,
        connectivityRepository: mockConnectivity,
        localDataSource: mockLocalDataSource,
        syncService: mockSyncService,
      );

      when(
        () => mockConnectivity.getCurrentStatus(),
      ).thenAnswer((_) async => DeviceSyncStatus.offline);

      expect(
        () => repositoryWithoutHomeId.createShoppingItem(
          listId: 'list-123',
          name: 'Milk',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('Missing homeId'),
          ),
        ),
      );
      verifyNever(
        () => mockQueue.enqueueAction(
          actionType: any(named: 'actionType'),
          entityType: any(named: 'entityType'),
          entityId: any(named: 'entityId'),
          homeId: any(named: 'homeId'),
          payload: any(named: 'payload'),
        ),
      );
      verifyNever(
        () => mockLocalDataSource.saveShoppingItemsStreamCache(
          listId: any(named: 'listId'),
          items: any(named: 'items'),
        ),
      );
    });
  });

  group('updateShoppingList', () {
    test('should update cached list and queue action when offline', () async {
      final cachedLists = [
        const ShoppingListModel(
          id: 'list-123',
          homeId: 'home-123',
          name: 'Old name',
          description: 'grocery',
          createdBy: 'user-123',
        ),
      ];
      List<ShoppingListModel>? savedLists;

      when(
        () => mockConnectivity.getCurrentStatus(),
      ).thenAnswer((_) async => DeviceSyncStatus.offline);
      when(
        () => mockLocalDataSource.getShoppingListsStreamCache(
          homeId: 'home-123',
          status: any(named: 'status'),
        ),
      ).thenAnswer((_) async => cachedLists);
      when(
        () => mockLocalDataSource.saveShoppingListsStreamCache(
          homeId: 'home-123',
          status: any(named: 'status'),
          lists: any(named: 'lists'),
        ),
      ).thenAnswer((invocation) async {
        savedLists =
            invocation.namedArguments[#lists] as List<ShoppingListModel>;
      });
      when(
        () => mockQueue.enqueueAction(
          actionType: any(named: 'actionType'),
          entityType: any(named: 'entityType'),
          entityId: any(named: 'entityId'),
          homeId: any(named: 'homeId'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});

      final result = await repository.updateShoppingList(
        listId: 'list-123',
        name: 'New name',
      );

      expect(result.name, 'New name');
      expect(savedLists, isNotNull);
      expect(savedLists!.single.name, 'New name');
      verify(
        () => mockQueue.enqueueAction(
          actionType: ActionType.updateList,
          entityType: EntityType.shoppingList,
          entityId: 'list-123',
          homeId: 'home-123',
          payload: any(named: 'payload'),
        ),
      ).called(1);
      verifyNever(
        () => mockRemote.updateShoppingList(
          listId: any(named: 'listId'),
          name: any(named: 'name'),
          description: any(named: 'description'),
          status: any(named: 'status'),
        ),
      );
    });
  });

  group('syncTemplateOnAdd', () {
    test('should not call remote repository when offline', () async {
      when(
        () => mockConnectivity.getCurrentStatus(),
      ).thenAnswer((_) async => DeviceSyncStatus.offline);

      await repository.syncTemplateOnAdd(
        homeId: 'home-123',
        name: 'Milk',
        quantity: 1,
      );

      verifyNever(
        () => mockRemote.syncTemplateOnAdd(
          homeId: any(named: 'homeId'),
          name: any(named: 'name'),
          quantity: any(named: 'quantity'),
          unitId: any(named: 'unitId'),
          categoryId: any(named: 'categoryId'),
        ),
      );
    });

    test('should swallow remote template sync failures', () async {
      when(
        () => mockConnectivity.getCurrentStatus(),
      ).thenAnswer((_) async => DeviceSyncStatus.online);
      when(
        () => mockRemote.syncTemplateOnAdd(
          homeId: any(named: 'homeId'),
          name: any(named: 'name'),
          quantity: any(named: 'quantity'),
          unitId: any(named: 'unitId'),
          categoryId: any(named: 'categoryId'),
        ),
      ).thenThrow(Exception('template sync failed'));

      await repository.syncTemplateOnAdd(
        homeId: 'home-123',
        name: 'Milk',
        quantity: 1,
      );

      verify(
        () => mockRemote.syncTemplateOnAdd(
          homeId: 'home-123',
          name: 'Milk',
          quantity: 1,
        ),
      ).called(1);
    });
  });

  group('deleteShoppingItem', () {
    test('should call remote when online', () async {
      when(
        () => mockConnectivity.getCurrentStatus(),
      ).thenAnswer((_) async => DeviceSyncStatus.online);
      when(
        () => mockRemote.deleteShoppingItem(itemId: any(named: 'itemId')),
      ).thenAnswer((_) async {});

      await repository.deleteShoppingItem(itemId: 'item-123');

      verify(() => mockRemote.deleteShoppingItem(itemId: 'item-123')).called(1);
    });

    test('should queue when offline', () async {
      when(
        () => mockConnectivity.getCurrentStatus(),
      ).thenAnswer((_) async => DeviceSyncStatus.offline);
      when(
        () => mockQueue.enqueueAction(
          actionType: any(named: 'actionType'),
          entityType: any(named: 'entityType'),
          entityId: any(named: 'entityId'),
          homeId: any(named: 'homeId'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});

      await repository.deleteShoppingItem(itemId: 'item-123');

      verify(
        () => mockQueue.enqueueAction(
          actionType: ActionType.deleteItem,
          entityType: EntityType.shoppingItem,
          entityId: 'item-123',
          homeId: 'home-123',
          payload: any(named: 'payload'),
        ),
      ).called(1);
    });
  });

  group('updateItemPurchaseState', () {
    test('queues one atomic update when offline', () async {
      const list = ShoppingListModel(
        id: 'list-123',
        homeId: 'home-123',
        name: 'Grocery',
        createdBy: 'user-123',
      );
      const item = ShoppingItemModel(
        id: 'item-123',
        shoppingListId: 'list-123',
        name: 'Rice',
        quantity: 4,
        createdBy: 'user-123',
      );

      when(
        () => mockConnectivity.getCurrentStatus(),
      ).thenAnswer((_) async => DeviceSyncStatus.offline);
      when(
        () => mockLocalDataSource.getShoppingListsStreamCache(
          homeId: 'home-123',
          status: any(named: 'status'),
        ),
      ).thenAnswer((_) async => [list]);
      when(
        () =>
            mockLocalDataSource.getShoppingItemsStreamCache(listId: 'list-123'),
      ).thenAnswer((_) async => [item]);
      when(
        () => mockQueue.enqueueAction(
          actionType: any(named: 'actionType'),
          entityType: any(named: 'entityType'),
          entityId: any(named: 'entityId'),
          homeId: any(named: 'homeId'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});

      final result = await repository.updateItemPurchaseState(
        itemId: 'item-123',
        purchasedQuantity: 2,
      );

      expect(result.purchasedQuantity, 2);
      expect(result.isPurchased, isFalse);
      verify(
        () => mockQueue.enqueueAction(
          actionType: ActionType.updateItem,
          entityType: EntityType.shoppingItem,
          entityId: 'item-123',
          homeId: 'home-123',
          payload: captureAny(named: 'payload'),
        ),
      ).called(1);
      verifyNever(
        () => mockRemote.updateShoppingItem(
          itemId: any(named: 'itemId'),
          purchasedQuantity: any(named: 'purchasedQuantity'),
        ),
      );
    });
  });

  group('getShoppingLists Local-First Single Source of Truth', () {
    test(
      'should strictly return cached lists from local cache and verify remote repository is never called',
      () async {
        final tLists = [
          const ShoppingListModel(
            id: 'list-123',
            homeId: 'home-123',
            name: 'Grocery',
            createdBy: 'user-123',
          ),
        ];

        when(
          () => mockLocalDataSource.getShoppingListsStreamCache(
            homeId: 'home-123',
            status: null,
          ),
        ).thenAnswer((_) async => tLists);

        final result = await repository.getShoppingLists(homeId: 'home-123');

        expect(result, tLists);
        verify(
          () => mockLocalDataSource.getShoppingListsStreamCache(
            homeId: 'home-123',
            status: null,
          ),
        ).called(1);
        verifyNever(
          () => mockRemote.getShoppingLists(
            homeId: any(named: 'homeId'),
            status: any(named: 'status'),
          ),
        );
      },
    );
  });

  group('syncShoppingWithServer', () {
    test(
      'does not refetch empty shopping lists after empty state was synced',
      () async {
        final syncTimes = <String, DateTime>{};
        final syncedDomains = <String>{};
        final serverUpdates = {
          'shopping_lists': DateTime.fromMillisecondsSinceEpoch(0),
          'shopping_items': DateTime.fromMillisecondsSinceEpoch(0),
        };

        when(
          () => mockSyncService.getServerLastUpdates('home-123'),
        ).thenAnswer((_) async => serverUpdates);
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
          () => mockRemote.getShoppingLists(
            homeId: 'home-123',
            status: any(named: 'status'),
          ),
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
        expect(
          syncTimes['shopping_lists'],
          DateTime.fromMicrosecondsSinceEpoch(1),
        );
      },
    );

    test(
      'does not refetch empty shopping items after empty item state was synced',
      () async {
        final syncTimes = <String, DateTime>{
          'shopping_lists': DateTime(2026, 1, 1),
        };
        final syncedDomains = <String>{'shopping_lists'};
        final serverUpdates = {
          'shopping_lists': DateTime.fromMillisecondsSinceEpoch(0),
          'shopping_items': DateTime.fromMillisecondsSinceEpoch(0),
        };
        final lists = [
          const ShoppingListModel(
            id: 'list-123',
            homeId: 'home-123',
            name: 'Grocery',
            createdBy: 'user-123',
          ),
        ];

        when(
          () => mockSyncService.getServerLastUpdates('home-123'),
        ).thenAnswer((_) async => serverUpdates);
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
          () => mockLocalDataSource.getShoppingListsStreamCache(
            homeId: 'home-123',
            status: any(named: 'status'),
          ),
        ).thenAnswer((_) async => lists);
        when(
          () => mockRemote.getShoppingItemsForLists(
            listIds: any(named: 'listIds'),
          ),
        ).thenAnswer((_) async => {'list-123': <ShoppingItemModel>[]});
        when(
          () => mockRemote.getItemTemplates(homeId: 'home-123'),
        ).thenAnswer((_) async => []);

        await repository.syncShoppingWithServer('home-123');
        await repository.syncShoppingWithServer('home-123');

        verify(
          () => mockRemote.getShoppingItemsForLists(
            listIds: any(named: 'listIds'),
            includeDeleted: true,
          ),
        ).called(1);
        verifyNever(() => mockRemote.getShoppingItems(listId: 'list-123'));
        expect(
          syncTimes['shopping_items'],
          DateTime.fromMicrosecondsSinceEpoch(1),
        );
      },
    );

    test(
      'preserves pending local shopping item when delta sync fetches server items',
      () async {
        final serverUpdates = {
          'shopping_lists': DateTime.fromMillisecondsSinceEpoch(0),
          'shopping_items': DateTime(2026, 1, 2),
        };
        const list = ShoppingListModel(
          id: 'list-123',
          homeId: 'home-123',
          name: 'Grocery',
          createdBy: 'user-123',
        );
        const localPendingItem = ShoppingItemModel(
          id: 'local-item-1',
          shoppingListId: 'list-123',
          name: 'Local Milk',
          quantity: 2,
          createdBy: 'user-123',
        );

        when(
          () => mockSyncService.getServerLastUpdates('home-123'),
        ).thenAnswer((_) async => serverUpdates);
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
            listId: 'list-123',
          ),
        ).thenAnswer((_) async => [localPendingItem]);
        when(
          () => mockRemote.getShoppingItemsForLists(
            listIds: any(named: 'listIds'),
          ),
        ).thenAnswer((_) async => {'list-123': <ShoppingItemModel>[]});
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
                    listId: 'list-123',
                    items: captureAny(named: 'items'),
                  ),
                ).captured.last
                as List<ShoppingItemModel>;

        expect(captured.map((item) => item.id), contains('local-item-1'));
        expect(captured.single.name, 'Local Milk');
      },
    );

    test('fetches shopping items for all lists with one batch query', () async {
      final serverUpdates = {
        'shopping_lists': DateTime.fromMillisecondsSinceEpoch(0),
        'shopping_items': DateTime(2026, 1, 2),
      };
      final lists = List.generate(
        20,
        (index) => ShoppingListModel(
          id: 'list-$index',
          homeId: 'home-123',
          name: 'List $index',
          createdBy: 'user-123',
        ),
      );

      when(
        () => mockSyncService.getServerLastUpdates('home-123'),
      ).thenAnswer((_) async => serverUpdates);
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
        () => mockLocalDataSource.getShoppingItemsStreamCache(
          listId: any(named: 'listId'),
        ),
      ).thenAnswer((_) async => []);
      when(
        () => mockRemote.getShoppingItemsForLists(
          listIds: any(named: 'listIds'),
          includeDeleted: any(named: 'includeDeleted'),
        ),
      ).thenAnswer(
        (_) async => {for (final list in lists) list.id: <ShoppingItemModel>[]},
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

      expect(capturedListIds, hasLength(20));
      verifyNever(
        () => mockRemote.getShoppingItems(listId: any(named: 'listId')),
      );
    });
  });
}
