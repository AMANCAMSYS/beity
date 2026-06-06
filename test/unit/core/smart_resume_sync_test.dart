import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sawa/core/services/sync_coordinator.dart';
import 'package:sawa/core/services/shared_prefs_provider.dart';
import 'package:sawa/core/services/sync_service.dart';
import 'package:sawa/features/tasks/domain/repositories/task_repository.dart';
import 'package:sawa/features/shopping_lists/data/repositories/shopping_list_repository.dart';
import 'package:sawa/features/expenses/domain/repositories/expense_repository.dart';
import 'package:sawa/features/inventory/data/repositories/inventory_repository.dart';
import 'package:sawa/features/categories/data/repositories/category_repository.dart';
import 'package:sawa/features/homes/data/repositories/home_repository.dart';
import 'package:sawa/features/offline_queue/data/repositories/offline_queue_repository.dart';
import 'package:sawa/features/offline_queue/domain/usecases/sync_queue_usecase.dart';
import 'package:sawa/features/tasks/presentation/providers/task_providers.dart';
import 'package:sawa/features/shopping_lists/presentation/providers/shopping_lists_provider.dart';
import 'package:sawa/features/expenses/presentation/providers/expense_providers.dart';
import 'package:sawa/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:sawa/features/categories/presentation/providers/categories_provider.dart';
import 'package:sawa/features/homes/presentation/providers/homes_provider.dart';
import 'package:sawa/features/offline_queue/presentation/providers/offline_queue_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSyncService extends Mock implements SyncService {}

class MockTaskRepository extends Mock implements TaskRepository {}

class MockShoppingListRepository extends Mock
    implements ShoppingListRepository {}

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockInventoryRepository extends Mock implements InventoryRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockHomeRepository extends Mock implements HomeRepository {}

class MockOfflineQueueRepository extends Mock
    implements OfflineQueueRepository {}

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
  late MockSyncService mockSyncService;
  late SyncCoordinator syncCoordinator;
  late ProviderContainer container;

  setUp(() async {
    mockTaskRepository = MockTaskRepository();
    mockShoppingListRepository = MockShoppingListRepository();
    mockExpenseRepository = MockExpenseRepository();
    mockInventoryRepository = MockInventoryRepository();
    mockCategoryRepository = MockCategoryRepository();
    mockHomeRepository = MockHomeRepository();
    mockOfflineQueueRepository = MockOfflineQueueRepository();
    mockSyncQueueUseCase = MockSyncQueueUseCase();
    mockSyncService = MockSyncService();

    SharedPreferences.setMockInitialValues({});
    await AppPreferences.init();

    container = ProviderContainer(
      overrides: [
        taskRepositoryProvider.overrideWithValue(mockTaskRepository),
        shoppingListRepositoryProvider.overrideWithValue(
          mockShoppingListRepository,
        ),
        expenseRepositoryProvider.overrideWithValue(mockExpenseRepository),
        inventoryRepositoryProvider.overrideWithValue(mockInventoryRepository),
        categoryRepositoryProvider.overrideWithValue(mockCategoryRepository),
        homeRepositoryProvider.overrideWithValue(mockHomeRepository),
        offlineQueueRepositoryProvider.overrideWithValue(
          mockOfflineQueueRepository,
        ),
        syncQueueUseCaseProvider.overrideWithValue(mockSyncQueueUseCase),
        syncServiceProvider.overrideWithValue(mockSyncService),
        cachedActiveHomeIdProvider.overrideWithValue(null),
      ],
    );
    syncCoordinator = container.read(syncCoordinatorProvider.notifier);

    // Default setups
    when(
      () => mockOfflineQueueRepository.getPendingCount(any()),
    ).thenAnswer((_) async => 0);
    when(
      () => mockShoppingListRepository.syncShoppingWithServer(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockHomeRepository.syncHomesWithServer(),
    ).thenAnswer((_) async {});
    when(
      () => mockHomeRepository.syncMembersWithServer(any()),
    ).thenAnswer((_) async => []);
  });

  tearDown(() {
    container.dispose();
  });

  group('SyncCoordinator - smartResumeSync', () {
    test(
      '1. Under 30 seconds: repairs shopping without syncing other domains',
      () async {
        const homeId = 'home-123';
        final now = DateTime.now();

        // Save last sync as 10 seconds ago
        final lastSyncTime = now.subtract(const Duration(seconds: 10));
        await syncCoordinator.updateLastSuccessfulSyncTime(
          homeId,
          lastSyncTime,
        );

        await syncCoordinator.smartResumeSync(homeId);

        verify(
          () => mockShoppingListRepository.syncShoppingWithServer(homeId),
        ).called(1);
        verifyNever(() => mockHomeRepository.syncHomesWithServer());
        verifyNever(() => mockHomeRepository.syncMembersWithServer(any()));
      },
    );

    test(
      '2. Processes pending outbox entries first if getPendingCount > 0',
      () async {
        const homeId = 'home-123';

        // Simulate pending outbox items
        when(
          () => mockOfflineQueueRepository.getPendingCount(homeId),
        ).thenAnswer((_) async => 2);
        when(() => mockSyncQueueUseCase.execute(homeId)).thenAnswer(
          (_) async =>
              SyncResult(successCount: 2, failedCount: 0, conflicts: []),
        );

        // Set last sync as 2 hours ago (so it triggers full sync)
        await syncCoordinator.updateLastSuccessfulSyncTime(
          homeId,
          DateTime.now().subtract(const Duration(hours: 2)),
        );

        // Stub full sync dependencies
        when(
          () => mockTaskRepository.syncTasksWithServer(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockExpenseRepository.syncExpensesWithServer(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockInventoryRepository.syncInventoryWithServer(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockCategoryRepository.syncCategoriesWithServer(any()),
        ).thenAnswer((_) async {});

        await syncCoordinator.smartResumeSync(homeId);

        // Verify outbox sync was called first
        verify(
          () => mockOfflineQueueRepository.getPendingCount(homeId),
        ).called(1);
        verify(() => mockSyncQueueUseCase.execute(homeId)).called(1);
      },
    );

    test('3. Under 5 minutes: repairs shopping on resume', () async {
      const homeId = 'home-123';

      // Set last sync as 2 minutes ago
      final lastSyncTime = DateTime.now().subtract(const Duration(minutes: 2));
      await syncCoordinator.updateLastSuccessfulSyncTime(homeId, lastSyncTime);

      await syncCoordinator.smartResumeSync(homeId);

      verify(
        () => mockShoppingListRepository.syncShoppingWithServer(homeId),
      ).called(1);
      verifyNever(() => mockHomeRepository.syncHomesWithServer());
      verifyNever(() => mockHomeRepository.syncMembersWithServer(any()));
    });

    test(
      '3b. Under 5 minutes: pulls shopping truth after outbox sync',
      () async {
        const homeId = 'home-123';

        when(
          () => mockOfflineQueueRepository.getPendingCount(homeId),
        ).thenAnswer((_) async => 1);
        when(() => mockSyncQueueUseCase.execute(homeId)).thenAnswer(
          (_) async =>
              SyncResult(successCount: 1, failedCount: 0, conflicts: []),
        );

        final lastSyncTime = DateTime.now().subtract(
          const Duration(minutes: 2),
        );
        await syncCoordinator.updateLastSuccessfulSyncTime(
          homeId,
          lastSyncTime,
        );

        await syncCoordinator.smartResumeSync(homeId);

        verify(() => mockSyncQueueUseCase.execute(homeId)).called(1);
        verify(
          () => mockShoppingListRepository.syncShoppingWithServer(homeId),
        ).called(1);
        verifyNever(() => mockHomeRepository.syncHomesWithServer());
      },
    );

    test('4. Under 60 minutes: runs Basic Sync with shopping catch-up', () async {
      const homeId = 'home-123';

      // Set last sync as 20 minutes ago
      final lastSyncTime = DateTime.now().subtract(const Duration(minutes: 20));
      await syncCoordinator.updateLastSuccessfulSyncTime(homeId, lastSyncTime);

      await syncCoordinator.smartResumeSync(homeId);

      // Verify homes, members, and shopping are synced for missed realtime repair.
      verify(() => mockHomeRepository.syncHomesWithServer()).called(1);
      verify(() => mockHomeRepository.syncMembersWithServer(homeId)).called(1);
      verify(
        () => mockShoppingListRepository.syncShoppingWithServer(homeId),
      ).called(1);

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
      when(
        () => mockTaskRepository.syncTasksWithServer(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockExpenseRepository.syncExpensesWithServer(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockInventoryRepository.syncInventoryWithServer(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockCategoryRepository.syncCategoriesWithServer(any()),
      ).thenAnswer((_) async {});

      await syncCoordinator.smartResumeSync(homeId);

      // Verify all domains, including shopping catch-up, are synced.
      verify(
        () => mockShoppingListRepository.syncShoppingWithServer(homeId),
      ).called(1);
      verify(() => mockHomeRepository.syncHomesWithServer()).called(1);
      verify(() => mockHomeRepository.syncMembersWithServer(homeId)).called(1);
      verify(() => mockTaskRepository.syncTasksWithServer(homeId)).called(1);
      verify(
        () => mockExpenseRepository.syncExpensesWithServer(homeId),
      ).called(1);
      verify(
        () => mockInventoryRepository.syncInventoryWithServer(homeId),
      ).called(1);
      verify(
        () => mockCategoryRepository.syncCategoriesWithServer(homeId),
      ).called(1);
    });
  });

  group('SyncCoordinator - targeted sync queue', () {
    test('runs targeted sync after current sync completes', () async {
      const homeId = 'home-123';
      final releaseHomesSync = Completer<void>();

      when(() => mockHomeRepository.syncHomesWithServer()).thenAnswer((
        _,
      ) async {
        await releaseHomesSync.future;
      });
      when(
        () => mockHomeRepository.syncMembersWithServer(homeId),
      ).thenAnswer((_) async => []);
      when(
        () => mockTaskRepository.syncTasksWithServer(homeId),
      ).thenAnswer((_) async {});
      when(
        () => mockExpenseRepository.syncExpensesWithServer(homeId),
      ).thenAnswer((_) async {});
      when(
        () => mockInventoryRepository.syncInventoryWithServer(homeId),
      ).thenAnswer((_) async {});
      when(
        () => mockCategoryRepository.syncCategoriesWithServer(homeId),
      ).thenAnswer((_) async {});

      final syncFuture = syncCoordinator.syncAll(homeId, force: true);
      await Future<void>.delayed(Duration.zero);

      await syncCoordinator.syncAll(homeId, targetDomain: 'home_members');

      releaseHomesSync.complete();
      await syncFuture;

      verify(() => mockHomeRepository.syncMembersWithServer(homeId)).called(2);
    });

    test('runs targeted shopping sync requests', () async {
      const homeId = 'home-123';

      await syncCoordinator.syncAll(
        homeId,
        force: true,
        targetDomain: 'shopping',
      );

      verify(
        () => mockShoppingListRepository.syncShoppingWithServer(homeId),
      ).called(1);
      verifyNever(() => mockHomeRepository.syncHomesWithServer());
      verifyNever(() => mockHomeRepository.syncMembersWithServer(any()));
    });

    test('repairMissing rewinds cursors before manual full sync', () async {
      const homeId = 'home-123';
      final resetTables = <List<String>>[];

      when(() => mockSyncService.resetLocalSyncTimes(any(), any())).thenAnswer((
        invocation,
      ) async {
        resetTables.add(
          List<String>.from(invocation.positionalArguments[1] as Iterable),
        );
      });
      when(
        () => mockTaskRepository.syncTasksWithServer(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockExpenseRepository.syncExpensesWithServer(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockInventoryRepository.syncInventoryWithServer(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockCategoryRepository.syncCategoriesWithServer(any()),
      ).thenAnswer((_) async {});

      final coordinator = container.read(syncCoordinatorProvider.notifier);

      await coordinator.syncAll(homeId, force: true, repairMissing: true);

      expect(
        resetTables,
        anyElement(orderedEquals(['shopping_lists', 'shopping_items'])),
      );
      expect(resetTables, anyElement(orderedEquals(['tasks'])));
      expect(resetTables, anyElement(orderedEquals(['expenses'])));
      expect(resetTables, anyElement(orderedEquals(['inventory_items'])));
      expect(resetTables, anyElement(orderedEquals(['categories'])));
      verify(
        () => mockShoppingListRepository.syncShoppingWithServer(homeId),
      ).called(1);
      verify(() => mockTaskRepository.syncTasksWithServer(homeId)).called(1);
      verify(
        () => mockExpenseRepository.syncExpensesWithServer(homeId),
      ).called(1);
      verify(
        () => mockInventoryRepository.syncInventoryWithServer(homeId),
      ).called(1);
      verify(
        () => mockCategoryRepository.syncCategoriesWithServer(homeId),
      ).called(1);
    });
  });

  group('SyncCoordinator - initial full sync status', () {
    void stubOptionalDomainsSuccess() {
      when(
        () => mockTaskRepository.syncTasksWithServer(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockExpenseRepository.syncExpensesWithServer(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockInventoryRepository.syncInventoryWithServer(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockCategoryRepository.syncCategoriesWithServer(any()),
      ).thenAnswer((_) async {});
    }

    test(
      'optional domain failure does not surface a global sync error',
      () async {
        const homeId = 'home-123';
        stubOptionalDomainsSuccess();
        when(
          () => mockInventoryRepository.syncInventoryWithServer(homeId),
        ).thenThrow(Exception('inventory temporarily unavailable'));

        await syncCoordinator.initialFullSync(homeId);
        await pumpEventQueue();

        expect(syncCoordinator.state.status, SyncStatus.partiallySynced);
        expect(syncCoordinator.state.domainErrors, contains('inventory'));
      },
    );

    test('shopping failure remains a critical bootstrap error', () async {
      const homeId = 'home-123';
      stubOptionalDomainsSuccess();
      when(
        () => mockShoppingListRepository.syncShoppingWithServer(homeId),
      ).thenThrow(Exception('shopping unavailable'));

      await expectLater(
        syncCoordinator.initialFullSync(homeId),
        throwsA(isA<StateError>()),
      );

      expect(syncCoordinator.state.status, SyncStatus.error);
      expect(syncCoordinator.state.domainErrors, contains('shopping'));
    });
  });
}
