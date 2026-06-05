import '../../domain/entities/queue_entry.dart';
import '../../domain/entities/action_type.dart';
import '../../domain/entities/entity_type.dart';
import '../../domain/entities/sync_status.dart';

abstract class OfflineQueueRepository {
  Future<void> enqueueAction({
    required ActionType actionType,
    required EntityType entityType,
    required String entityId,
    String? homeId,
    MutationScope scope = MutationScope.home,
    required Map<String, dynamic> payload,
  });

  Future<List<QueueEntry>> getEntriesByHome(String homeId);

  Future<List<QueueEntry>> getEntriesByUserScope(String userId);

  Future<List<QueueEntry>> getEntriesByGlobalScope();

  Future<List<QueueEntry>> getEntriesByStatus(SyncStatus status);

  Future<int> getPendingCount(String homeId);

  Future<int> getPendingCountForUser(String userId);

  Future<QueueEntry?> getEntryById(int id);

  Future<void> updateEntryStatus({
    required int entryId,
    required SyncStatus status,
    String? errorMessage,
  });

  Future<void> deleteEntry(int entryId);

  Future<void> deleteCompletedEntries(String homeId);

  Future<List<QueueEntry>> getFailedEntries(String homeId);

  Future<void> resetProcessingToPending(String homeId);

  Future<void> resetProcessingToPendingForUserScope(String userId);
}
