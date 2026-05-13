import '../../data/repositories/offline_queue_repository.dart';
import '../entities/queue_entry.dart';
import '../entities/sync_status.dart';

class GetQueueEntriesUseCase {
  final OfflineQueueRepository repository;

  GetQueueEntriesUseCase(this.repository);

  Future<List<QueueEntry>> execute({
    required String homeId,
    SyncStatus? statusFilter,
  }) async {
    if (statusFilter != null) {
      return repository.getEntriesByStatus(statusFilter);
    }
    return repository.getEntriesByHome(homeId);
  }
}
