import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sawa/core/services/supabase_service.dart';

import '../../data/datasources/drift_queue_datasource.dart';
import '../../data/datasources/queue_datasource.dart';
import '../../data/repositories/offline_queue_repository.dart';
import '../../data/repositories/offline_queue_repository_impl.dart';
import '../../data/datasources/queue_action_executor.dart';
import '../../domain/entities/queue_entry.dart';
import '../../domain/entities/sync_status.dart';
import '../../domain/usecases/enqueue_action_usecase.dart';
import '../../domain/usecases/get_pending_count_usecase.dart';
import '../../domain/usecases/get_queue_entries_usecase.dart';
import '../../domain/usecases/sync_queue_usecase.dart';
import 'connectivity_provider.dart';
import '../../../../core/services/sync_service.dart';

final queueDataSourceProvider = Provider<QueueDataSource>((ref) {
  return DriftQueueDataSource();
});

final offlineQueueRepositoryProvider = Provider<OfflineQueueRepository>((ref) {
  final dataSource = ref.watch(queueDataSourceProvider);
  return OfflineQueueRepositoryImpl(dataSource);
});

final enqueueActionUseCaseProvider = Provider<EnqueueActionUseCase>((ref) {
  final repository = ref.watch(offlineQueueRepositoryProvider);
  return EnqueueActionUseCase(repository);
});

final getPendingCountUseCaseProvider = Provider<GetPendingCountUseCase>((ref) {
  final repository = ref.watch(offlineQueueRepositoryProvider);
  return GetPendingCountUseCase(repository);
});

final getQueueEntriesUseCaseProvider = Provider<GetQueueEntriesUseCase>((ref) {
  final repository = ref.watch(offlineQueueRepositoryProvider);
  return GetQueueEntriesUseCase(repository);
});

final queueActionExecutorProvider = Provider<QueueActionExecutor>((ref) {
  return QueueActionExecutor(SupabaseService.client);
});

final syncQueueLockProvider = Provider<SyncQueueLock>((ref) {
  return SyncQueueLock();
});

final syncQueueUseCaseProvider = Provider<SyncQueueUseCase>((ref) {
  final queueRepository = ref.watch(offlineQueueRepositoryProvider);
  final connectivityRepository = ref.watch(connectivityRepositoryProvider);
  final executor = ref.watch(queueActionExecutorProvider);
  final syncService = ref.watch(syncServiceProvider);
  final syncLock = ref.watch(syncQueueLockProvider);

  return SyncQueueUseCase(
    queueRepository: queueRepository,
    connectivityRepository: connectivityRepository,
    executeAction: (QueueEntry entry) => executor.execute(entry),
    syncService: syncService,
    checkCanSyncNow: () async => ref.read(canSyncNowProvider),
    syncLock: syncLock,
  );
});

final pendingCountProvider = FutureProvider.family<int, String>((
  ref,
  homeId,
) async {
  final useCase = ref.watch(getPendingCountUseCaseProvider);
  return useCase.execute(homeId);
});

final failedCountProvider = FutureProvider.family<int, String>((
  ref,
  homeId,
) async {
  final repository = ref.watch(offlineQueueRepositoryProvider);
  final failed = await repository.getFailedEntries(homeId);
  return failed.length;
});

final queueEntriesProvider = FutureProvider.family<List<QueueEntry>, String>((
  ref,
  homeId,
) async {
  final useCase = ref.watch(getQueueEntriesUseCaseProvider);
  return useCase.execute(homeId: homeId);
});

final queueEntriesByStatusProvider =
    FutureProvider.family<
      List<QueueEntry>,
      ({String homeId, SyncStatus status})
    >((ref, params) async {
      final useCase = ref.watch(getQueueEntriesUseCaseProvider);
      return useCase.execute(
        homeId: params.homeId,
        statusFilter: params.status,
      );
    });
