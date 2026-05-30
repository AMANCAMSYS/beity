import '../../domain/entities/queue_entry.dart';
import '../../domain/entities/action_type.dart';
import '../../domain/entities/entity_type.dart';
import '../../domain/entities/sync_status.dart';

abstract class QueueDataSource {
  Future<void> clearQueue();
  
  Future<void> clearQueueForUser(String userId);
  
  Future<int> enqueueAction({
    required ActionType actionType,
    required EntityType entityType,
    required String entityId,
    required String homeId,
    required Map<String, dynamic> payload,
  });
  
  Future<List<QueueEntry>> getEntriesByHome(String homeId);
  
  Future<List<QueueEntry>> getEntriesByStatus(SyncStatus status);
  
  Future<int> getPendingCount(String homeId);
  
  Future<QueueEntry?> getEntryById(int id);
  
  Future<void> updateEntryStatus({
    required int entryId,
    required SyncStatus status,
    String? errorMessage,
  });
  
  Future<void> deleteEntry(int entryId);
  
  Future<void> deleteCompletedEntries(String homeId);
  
  Future<List<QueueEntry>> getFailedEntries(String homeId);

  // Recovery helper
  Future<void> resetProcessingToPending(String homeId);
}
