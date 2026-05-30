import 'package:flutter_test/flutter_test.dart';
import 'package:beity/features/offline_queue/domain/usecases/sync_queue_usecase.dart';
import 'package:beity/features/offline_queue/data/repositories/offline_queue_repository.dart';
import 'package:beity/features/offline_queue/data/repositories/connectivity_repository.dart';
import 'package:beity/features/offline_queue/domain/entities/queue_entry.dart';
import 'package:beity/features/offline_queue/domain/entities/device_sync_status.dart';

class MockOfflineQueueRepository implements OfflineQueueRepository {
  bool resetCalled = false;
  
  @override
  Future<void> resetProcessingToPending(String homeId) async {
    resetCalled = true;
  }

  @override
  Future<List<QueueEntry>> getEntriesByHome(String homeId) async {
    return [];
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
  test('SyncQueueUseCase aborts sync if checkCanSyncNow returns false', () async {
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
  });

  test('SyncQueueUseCase continues sync if checkCanSyncNow returns true', () async {
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
  });
}
