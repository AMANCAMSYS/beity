import '../../data/repositories/offline_queue_repository.dart';
import '../entities/sync_status.dart';

class RetryFailedActionUseCase {
  final OfflineQueueRepository repository;
  final Future<void> Function(int entryId) syncEntry;

  RetryFailedActionUseCase({required this.repository, required this.syncEntry});

  Future<void> execute(int entryId) async {
    final entry = await repository.getEntryById(entryId);
    if (entry == null) {
      throw Exception('Queue entry not found: $entryId');
    }

    if (!entry.isFailed) {
      throw Exception('Entry is not in failed state: $entryId');
    }

    // Reset status to pending and sync
    await repository.updateEntryStatus(
      entryId: entryId,
      status: SyncStatus.pending,
    );

    await syncEntry(entryId);
  }
}
