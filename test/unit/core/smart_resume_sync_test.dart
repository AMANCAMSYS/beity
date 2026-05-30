import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:beity/core/services/sync_coordinator.dart';
import 'package:beity/core/services/shared_prefs_provider.dart';
import 'package:beity/features/tasks/domain/repositories/task_repository.dart';
import 'package:beity/features/shopping_lists/data/repositories/shopping_list_repository.dart';
import 'package:beity/features/expenses/domain/repositories/expense_repository.dart';
import 'package:beity/features/inventory/data/repositories/inventory_repository.dart';
import 'package:beity/features/categories/data/repositories/category_repository.dart';
import 'package:beity/features/homes/data/repositories/home_repository.dart';
import 'package:beity/features/offline_queue/data/repositories/offline_queue_repository.dart';
import 'package:beity/features/offline_queue/domain/usecases/sync_queue_usecase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockTaskRepository extends Mock implements TaskRepository {}
class MockShoppingListRepository extends Mock implements ShoppingListRepository {}
class MockExpenseRepository extends Mock implements ExpenseRepository {}
class MockInventoryRepository extends Mock implements InventoryRepository {}
class MockCategoryRepository extends Mock implements CategoryRepository {}
class MockHomeRepository extends Mock implements HomeRepository {}
class MockOfflineQueueRepository extends Mock implements OfflineQueueRepository {}
class MockSyncQueueUseCase extends Mock implements SyncQueueUseCase {}

void main() {
  late MockTaskRepository mockTaskRepository;
  late MockShoppingListRepository mockShoppingListRepository;
  late MockExpenseRepository mockExpenseRepository;
  late MockInventoryRepository mockInventoryRepository;
  late MockCategoryRepository mockCategoryRepository;
  late MockHomeRepository mockHomeRepository;
  late MockOfflineQueueRepository mockOfflineQueueRepository;
  late MockSyncQueueUseCase mockSyncQueueUseCase;
  late SyncCoordinator syncCoordinator;

  setUp(() async {
    mockTaskRepository = MockTaskRepository();
    mockShoppingListRepository = MockShoppingListRepository();
    mockExpenseRepository = MockExpenseRepository();
    mockInventoryRepository = MockInventoryRepository();
    mockCategoryRepository = MockCategoryRepository();
    mockHomeRepository = MockHomeRepository();
    mockOfflineQueueRepository = MockOfflineQueueRepository();
    mockSyncQueueUseCase = MockSyncQueueUseCase();

    SharedPreferences.setMockInitialValues({});
    await AppPreferences.init();

    syncCoordinator = SyncCoordinator(
      taskRepository: mockTaskRepository,
      shoppingRepository: mockShoppingListRepository,
      expenseRepository: mockExpenseRepository,
      inventoryRepository: mockInventoryRepository,
      categoryRepository: mockCategoryRepository,
      homeRepository: mockHomeRepository,
      offlineQueueRepository: mockOfflineQueueRepository,
      syncQueueUseCase: mockSyncQueueUseCase,
    );

    // Default setups
    when(() => mockOfflineQueueRepository.getPendingCount(any())).thenAnswer((_) async => 0);
    when(() => mockShoppingListRepository.syncShoppingWithServer(any())).thenAnswer((_) async {});
    when(() => mockHomeRepository.syncHomesWithServer()).thenAnswer((_) async {});
    when(() => mockHomeRepository.syncMembersWithServer(any())).thenAnswer((_) async => []);
  });

  group('SyncCoordinator - smartResumeSync', () {
    test('1. Does nothing if elapsed duration since last sync is < 30 seconds', () async {
      const homeId = 'home-123';
      final now = DateTime.now();
      
      // Save last sync as 10 seconds ago
      final lastSyncTime = now.subtract(const Duration(seconds: 10));
      await syncCoordinator.updateLastSuccessfulSyncTime(homeId, lastSyncTime);

      await syncCoordinator.smartResumeSync(homeId);

      // Verify that NO repository sync method is called
      verifyNever(() => mockShoppingListRepository.syncShoppingWithServer(any()));
      verifyNever(() => mockHomeRepository.syncHomesWithServer());
      expect(syncCoordinator.state.status, SyncStatus.idle);
    });

    test('2. Processes pending outbox entries first if getPendingCount > 0', () async {
      const homeId = 'home-123';
      
      // Simulate pending outbox items
      when(() => mockOfflineQueueRepository.getPendingCount(homeId)).thenAnswer((_) async => 2);
      when(() => mockSyncQueueUseCase.execute(homeId)).thenAnswer((_) async => SyncResult(
        successCount: 2,
        failedCount: 0,
        conflicts: [],
      ));

      // Set last sync as 2 hours ago (so it triggers full sync)
      await syncCoordinator.updateLastSuccessfulSyncTime(homeId, DateTime.now().subtract(const Duration(hours: 2)));

      // Stub full sync dependencies
      when(() => mockTaskRepository.syncTasksWithServer(any())).thenAnswer((_) async {});
      when(() => mockExpenseRepository.syncExpensesWithServer(any())).thenAnswer((_) async {});
      when(() => mockInventoryRepository.syncInventoryWithServer(any())).thenAnswer((_) async {});
      when(() => mockCategoryRepository.syncCategoriesWithServer(any())).thenAnswer((_) async {});

      await syncCoordinator.smartResumeSync(homeId);

      // Verify outbox sync was called first
      verify(() => mockOfflineQueueRepository.getPendingCount(homeId)).called(1);
      verify(() => mockSyncQueueUseCase.execute(homeId)).called(1);
    });

    test('3. Under 5 minutes: runs Light Sync (Shopping only)', () async {
      const homeId = 'home-123';
      
      // Set last sync as 2 minutes ago
      final lastSyncTime = DateTime.now().subtract(const Duration(minutes: 2));
      await syncCoordinator.updateLastSuccessfulSyncTime(homeId, lastSyncTime);

      await syncCoordinator.smartResumeSync(homeId);

      // Verify ONLY shopping was synced
      verify(() => mockShoppingListRepository.syncShoppingWithServer(homeId)).called(1);
      verifyNever(() => mockHomeRepository.syncHomesWithServer());
      verifyNever(() => mockHomeRepository.syncMembersWithServer(any()));
    });

    test('4. Under 60 minutes: runs Basic Sync (Shopping, Homes, Members)', () async {
      const homeId = 'home-123';
      
      // Set last sync as 20 minutes ago
      final lastSyncTime = DateTime.now().subtract(const Duration(minutes: 20));
      await syncCoordinator.updateLastSuccessfulSyncTime(homeId, lastSyncTime);

      await syncCoordinator.smartResumeSync(homeId);

      // Verify shopping, homes, and members are synced
      verify(() => mockShoppingListRepository.syncShoppingWithServer(homeId)).called(1);
      verify(() => mockHomeRepository.syncHomesWithServer()).called(1);
      verify(() => mockHomeRepository.syncMembersWithServer(homeId)).called(1);

      // Verify categories/tasks are NOT synced
      verifyNever(() => mockTaskRepository.syncTasksWithServer(any()));
      verifyNever(() => mockExpenseRepository.syncExpensesWithServer(any()));
    });

    test('5. >= 60 minutes or first run: runs Full Background Sync', () async {
      const homeId = 'home-123';
      
      // Set last sync as 3 hours ago
      final lastSyncTime = DateTime.now().subtract(const Duration(hours: 3));
      await syncCoordinator.updateLastSuccessfulSyncTime(homeId, lastSyncTime);

      // Stub remaining sync methods
      when(() => mockTaskRepository.syncTasksWithServer(any())).thenAnswer((_) async {});
      when(() => mockExpenseRepository.syncExpensesWithServer(any())).thenAnswer((_) async {});
      when(() => mockInventoryRepository.syncInventoryWithServer(any())).thenAnswer((_) async {});
      when(() => mockCategoryRepository.syncCategoriesWithServer(any())).thenAnswer((_) async {});

      await syncCoordinator.smartResumeSync(homeId);

      // Verify all domains are synced
      verify(() => mockShoppingListRepository.syncShoppingWithServer(homeId)).called(1);
      verify(() => mockHomeRepository.syncHomesWithServer()).called(1);
      verify(() => mockHomeRepository.syncMembersWithServer(homeId)).called(1);
      verify(() => mockTaskRepository.syncTasksWithServer(homeId)).called(1);
      verify(() => mockExpenseRepository.syncExpensesWithServer(homeId)).called(1);
      verify(() => mockInventoryRepository.syncInventoryWithServer(homeId)).called(1);
      verify(() => mockCategoryRepository.syncCategoriesWithServer(homeId)).called(1);
    });
  });
}
