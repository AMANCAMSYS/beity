import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/features/offline_queue/domain/usecases/sync_queue_usecase.dart';
import 'package:sawa/features/offline_queue/data/repositories/offline_queue_repository.dart';
import 'package:sawa/features/offline_queue/data/repositories/connectivity_repository.dart';
import 'package:sawa/features/offline_queue/domain/entities/action_type.dart';
import 'package:sawa/features/offline_queue/domain/entities/queue_entry.dart';
import 'package:sawa/features/offline_queue/domain/entities/device_sync_status.dart';
import 'package:sawa/features/offline_queue/domain/entities/entity_type.dart';
import 'package:sawa/features/offline_queue/domain/entities/sync_status.dart';

class MockOfflineQueueRepository implements OfflineQueueRepository {
  bool resetCalled = false;
  final List<QueueEntry> entries = [];

  @override
  Future<void> resetProcessingToPending(String homeId) async {
    resetCalled = true;
  }

  @override
  Future<List<QueueEntry>> getEntriesByHome(String homeId) async {
    return entries.where((entry) => entry.homeId == homeId).toList();
  }

  @override
  Future<void> updateEntryStatus({
    required int entryId,
    required SyncStatus status,
    String? errorMessage,
  }) async {
    final index = entries.indexWhere((entry) => entry.id == entryId);
    if (index == -1) return;
    entries[index] = entries[index].copyWith(
      syncStatus: status,
      errorMessage: errorMessage,
    );
  }

  @override
  Future<void> deleteEntry(int entryId) async {
    entries.removeWhere((entry) => entry.id == entryId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockConnectivityRepository implements ConnectivityRepository {
  @override
  Future<DeviceSyncStatus> getCurrentStatus() async {
    return DeviceSyncStatus.online;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'SyncQueueUseCase aborts sync if checkCanSyncNow returns false',
    () async {
      final queueRepo = MockOfflineQueueRepository();
      final connRepo = MockConnectivityRepository();

      final useCase = SyncQueueUseCase(
        queueRepository: queueRepo,
        connectivityRepository: connRepo,
        executeAction: (entry) async => entry.entityId,
        checkCanSyncNow: () async => false,
      );

      final result = await useCase.execute('home_123');

      expect(result.successCount, 0);
      expect(result.failedCount, 0);
      expect(queueRepo.resetCalled, false);
    },
  );

  test(
    'SyncQueueUseCase continues sync if checkCanSyncNow returns true',
    () async {
      final queueRepo = MockOfflineQueueRepository();
      final connRepo = MockConnectivityRepository();

      final useCase = SyncQueueUseCase(
        queueRepository: queueRepo,
        connectivityRepository: connRepo,
        executeAction: (entry) async => entry.entityId,
        checkCanSyncNow: () async => true,
      );

      final result = await useCase.execute('home_123');

      expect(result.successCount, 0);
      expect(queueRepo.resetCalled, true);
    },
  );

  test(
    'SyncQueueUseCase skips failed entries before next retry time',
    () async {
      final queueRepo = MockOfflineQueueRepository();
      final connRepo = MockConnectivityRepository();
      var executeCount = 0;

      queueRepo.entries.add(
        QueueEntry(
          id: 1,
          actionType: ActionType.updateItem,
          entityType: EntityType.shoppingItem,
          entityId: 'item-1',
          homeId: 'home_123',
          payload: {'name': 'Milk'},
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
          syncStatus: SyncStatus.failed,
          retryCount: 1,
          lastRetryAt: DateTime.now().add(const Duration(minutes: 5)),
          errorMessage: 'Timeout',
        ),
      );

      final useCase = SyncQueueUseCase(
        queueRepository: queueRepo,
        connectivityRepository: connRepo,
        executeAction: (entry) async {
          executeCount++;
          return entry.entityId;
        },
        checkCanSyncNow: () async => true,
      );

      final result = await useCase.execute('home_123');

      expect(result.successCount, 0);
      expect(result.failedCount, 0);
      expect(executeCount, 0);
      expect(queueRepo.entries.single.syncStatus, SyncStatus.failed);
    },
  );
}
