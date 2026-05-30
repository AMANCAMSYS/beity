import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:beity/features/shopping_lists/data/repositories/shopping_list_repository.dart';
import 'package:beity/features/shopping_lists/data/models/shopping_item_model.dart';
import 'package:beity/features/shopping_lists/data/models/shopping_list_model.dart';
import 'package:beity/features/offline_queue/data/repositories/offline_queue_repository.dart';
import 'package:beity/features/offline_queue/data/repositories/connectivity_repository.dart';
import 'package:beity/features/offline_queue/data/repositories/offline_aware_shopping_repository.dart';
import 'package:beity/features/shopping_lists/data/datasources/shopping_local_datasource.dart';
import 'package:beity/core/services/sync_service.dart';
import 'package:beity/features/offline_queue/domain/entities/device_sync_status.dart';
import 'package:beity/features/offline_queue/domain/entities/action_type.dart';
import 'package:beity/features/offline_queue/domain/entities/entity_type.dart';

class MockShoppingListRepository extends Mock implements ShoppingListRepository {}
class MockOfflineQueueRepository extends Mock implements OfflineQueueRepository {}
class MockConnectivityRepository extends Mock implements ConnectivityRepository {}
class MockSyncService extends Mock implements SyncService {}
class MockShoppingLocalDataSource extends Mock implements ShoppingLocalDataSource {}

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
    when(() => mockLocalDataSource.getShoppingListsStreamCache(homeId: any(named: 'homeId'), status: any(named: 'status')))
        .thenAnswer((_) async => []);
    when(() => mockLocalDataSource.saveShoppingListsStreamCache(homeId: any(named: 'homeId'), status: any(named: 'status'), lists: any(named: 'lists')))
        .thenAnswer((_) async {});
    when(() => mockLocalDataSource.getShoppingItemsStreamCache(listId: any(named: 'listId')))
        .thenAnswer((_) async => []);
    when(() => mockLocalDataSource.saveShoppingItemsStreamCache(listId: any(named: 'listId'), items: any(named: 'items')))
        .thenAnswer((_) async {});
    when(() => mockLocalDataSource.getLastLoggedInUserId())
        .thenAnswer((_) async => 'anonymous');

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
      anonKey: 'placeholderAnonKey',
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
      when(() => mockConnectivity.getCurrentStatus())
          .thenAnswer((_) async => DeviceSyncStatus.online);
      when(() => mockRemote.createShoppingItem(
            id: any(named: 'id'),
            listId: any(named: 'listId'),
            name: any(named: 'name'),
            quantity: any(named: 'quantity'),
            unitId: any(named: 'unitId'),
            categoryId: any(named: 'categoryId'),
            price: any(named: 'price'),
            currency: any(named: 'currency'),
            notes: any(named: 'notes'),
          )).thenAnswer((_) async => tItem);

      final result = await repository.createShoppingItem(
        listId: 'list-123',
        name: 'Milk',
      );

      expect(result.name, 'Milk');
      verify(() => mockRemote.createShoppingItem(
            id: any(named: 'id'),
            listId: 'list-123',
            name: 'Milk',
          )).called(1);
      verifyNever(() => mockQueue.enqueueAction(
            actionType: any(named: 'actionType'),
            entityType: any(named: 'entityType'),
            entityId: any(named: 'entityId'),
            homeId: any(named: 'homeId'),
            payload: any(named: 'payload'),
          ));
    });

    test('should queue action when offline', () async {
      when(() => mockConnectivity.getCurrentStatus())
          .thenAnswer((_) async => DeviceSyncStatus.offline);
      when(() => mockQueue.enqueueAction(
            actionType: any(named: 'actionType'),
            entityType: any(named: 'entityType'),
            entityId: any(named: 'entityId'),
            homeId: any(named: 'homeId'),
            payload: any(named: 'payload'),
          )).thenAnswer((_) async {});

      final result = await repository.createShoppingItem(
        listId: 'list-123',
        name: 'Milk',
      );

      // Returns optimistic model
      expect(result.name, 'Milk');
      verify(() => mockQueue.enqueueAction(
            actionType: ActionType.addItem,
            entityType: EntityType.shoppingItem,
            entityId: any(named: 'entityId'),
            homeId: 'home-123',
            payload: any(named: 'payload'),
          )).called(1);
      verifyNever(() => mockRemote.createShoppingItem(
            id: any(named: 'id'),
            listId: any(named: 'listId'),
            name: any(named: 'name'),
          ));
    });
  });

  group('deleteShoppingItem', () {
    test('should call remote when online', () async {
      when(() => mockConnectivity.getCurrentStatus())
          .thenAnswer((_) async => DeviceSyncStatus.online);
      when(() => mockRemote.deleteShoppingItem(itemId: any(named: 'itemId')))
          .thenAnswer((_) async {});

      await repository.deleteShoppingItem(itemId: 'item-123');

      verify(() => mockRemote.deleteShoppingItem(itemId: 'item-123')).called(1);
    });

    test('should queue when offline', () async {
      when(() => mockConnectivity.getCurrentStatus())
          .thenAnswer((_) async => DeviceSyncStatus.offline);
      when(() => mockQueue.enqueueAction(
            actionType: any(named: 'actionType'),
            entityType: any(named: 'entityType'),
            entityId: any(named: 'entityId'),
            homeId: any(named: 'homeId'),
            payload: any(named: 'payload'),
          )).thenAnswer((_) async {});

      await repository.deleteShoppingItem(itemId: 'item-123');

      verify(() => mockQueue.enqueueAction(
            actionType: ActionType.deleteItem,
            entityType: EntityType.shoppingItem,
            entityId: 'item-123',
            homeId: 'home-123',
            payload: any(named: 'payload'),
          )).called(1);
    });
  });

  group('getShoppingLists Local-First Single Source of Truth', () {
    test('should strictly return cached lists from local cache and verify remote repository is never called', () async {
      final tLists = [
        const ShoppingListModel(
          id: 'list-123',
          homeId: 'home-123',
          name: 'Grocery',
          createdBy: 'user-123',
        )
      ];
      
      when(() => mockLocalDataSource.getShoppingListsStreamCache(
        homeId: 'home-123',
        status: null,
      )).thenAnswer((_) async => tLists);

      final result = await repository.getShoppingLists(homeId: 'home-123');

      expect(result, tLists);
      verify(() => mockLocalDataSource.getShoppingListsStreamCache(
        homeId: 'home-123',
        status: null,
      )).called(1);
      verifyNever(() => mockRemote.getShoppingLists(
        homeId: any(named: 'homeId'),
        status: any(named: 'status'),
      ));
    });
  });
}
