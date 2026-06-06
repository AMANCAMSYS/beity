import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sawa/features/offline_queue/data/repositories/offline_aware_shopping_repository.dart';
import 'package:sawa/features/shopping_lists/data/repositories/shopping_list_repository.dart';
import 'package:sawa/features/shopping_lists/data/datasources/shopping_local_datasource.dart';
import 'package:sawa/features/offline_queue/data/repositories/offline_queue_repository.dart';
import 'package:sawa/features/offline_queue/data/repositories/connectivity_repository.dart';
import 'package:sawa/features/offline_queue/domain/entities/action_type.dart';
import 'package:sawa/features/offline_queue/domain/entities/device_sync_status.dart';
import 'package:sawa/features/offline_queue/domain/entities/entity_type.dart';
import 'package:sawa/core/services/sync_service.dart';
import 'package:sawa/features/shopping_lists/data/models/shopping_list_model.dart';

class MockShoppingListRepository extends Mock
    implements ShoppingListRepository {}

class MockShoppingLocalDataSource extends Mock
    implements ShoppingLocalDataSource {}

class MockOfflineQueueRepository extends Mock
    implements OfflineQueueRepository {}

class MockConnectivityRepository extends Mock
    implements ConnectivityRepository {}

class MockSyncService extends Mock implements SyncService {}

void main() {
  setUpAll(() {
    registerFallbackValue(ActionType.deleteItem);
    registerFallbackValue(EntityType.shoppingList);
    registerFallbackValue(<ShoppingListModel>[]);
  });

  group('OfflineAwareShoppingRepository', () {
    test('deleteShoppingList queues soft delete when offline', () async {
      final mockRemoteRepo = MockShoppingListRepository();
      final mockLocalDS = MockShoppingLocalDataSource();
      final mockQueueRepo = MockOfflineQueueRepository();
      final mockConnectivity = MockConnectivityRepository();
      final mockSyncService = MockSyncService();

      when(
        () => mockConnectivity.getCurrentStatus(),
      ).thenAnswer((_) async => DeviceSyncStatus.offline);
      when(
        () => mockLocalDS.getLastLoggedInUserId(),
      ).thenAnswer((_) async => 'user_123');
      when(
        () => mockLocalDS.getShoppingListsStreamCache(
          homeId: 'home_123',
          status: any(named: 'status'),
        ),
      ).thenAnswer(
        (_) async => [
          const ShoppingListModel(
            id: 'list_123',
            homeId: 'home_123',
            name: 'Groceries',
            createdBy: 'user_123',
          ),
        ],
      );
      when(
        () => mockLocalDS.saveShoppingListsStreamCache(
          homeId: any(named: 'homeId'),
          lists: any(named: 'lists'),
          status: any(named: 'status'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => mockQueueRepo.enqueueAction(
          actionType: any(named: 'actionType'),
          entityType: any(named: 'entityType'),
          entityId: any(named: 'entityId'),
          homeId: any(named: 'homeId'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});

      final repo = OfflineAwareShoppingRepository(
        remoteRepository: mockRemoteRepo,
        localDataSource: mockLocalDS,
        queueRepository: mockQueueRepo,
        connectivityRepository: mockConnectivity,
        syncService: mockSyncService,
        homeId: 'home_123',
      );

      await repo.deleteShoppingList(listId: 'list_123');

      verify(
        () => mockLocalDS.saveShoppingListsStreamCache(
          homeId: 'home_123',
          lists: <ShoppingListModel>[],
          status: any(named: 'status'),
        ),
      ).called(1);
      verify(
        () => mockQueueRepo.enqueueAction(
          actionType: ActionType.deleteList,
          entityType: EntityType.shoppingList,
          entityId: 'list_123',
          homeId: 'home_123',
          payload: any(named: 'payload'),
        ),
      ).called(1);
      verifyNever(
        () => mockRemoteRepo.deleteShoppingList(listId: any(named: 'listId')),
      );
    });
  });
}
