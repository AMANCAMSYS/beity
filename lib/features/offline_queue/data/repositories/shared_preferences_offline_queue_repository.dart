import '../../domain/entities/queue_entry.dart';
import '../../domain/entities/action_type.dart';
import '../../domain/entities/entity_type.dart';
import '../../domain/entities/sync_status.dart';
import '../datasources/queue_datasource.dart';
import 'offline_queue_repository.dart';

class SharedPreferencesOfflineQueueRepository implements OfflineQueueRepository {
  final QueueDataSource dataSource;

  SharedPreferencesOfflineQueueRepository(this.dataSource);

  @override
  Future<void> enqueueAction({
    required ActionType actionType,
    required EntityType entityType,
    required String entityId,
    required String homeId,
    required Map<String, dynamic> payload,
  }) async {
    await dataSource.enqueueAction(
      actionType: actionType,
      entityType: entityType,
      entityId: entityId,
      homeId: homeId,
      payload: payload,
    );
  }

  @override
  Future<List<QueueEntry>> getEntriesByHome(String homeId) {
    return dataSource.getEntriesByHome(homeId);
  }

  @override
  Future<List<QueueEntry>> getEntriesByStatus(SyncStatus status) {
    return dataSource.getEntriesByStatus(status);
  }

  @override
  Future<int> getPendingCount(String homeId) {
    return dataSource.getPendingCount(homeId);
  }

  @override
  Future<QueueEntry?> getEntryById(int id) {
    return dataSource.getEntryById(id);
  }

  @override
  Future<void> updateEntryStatus({
    required int entryId,
    required SyncStatus status,
    String? errorMessage,
  }) {
    return dataSource.updateEntryStatus(
      entryId: entryId,
      status: status,
      errorMessage: errorMessage,
    );
  }

  @override
  Future<void> deleteEntry(int entryId) {
    return dataSource.deleteEntry(entryId);
  }

  @override
  Future<void> deleteCompletedEntries(String homeId) {
    return dataSource.deleteCompletedEntries(homeId);
  }

  @override
  Future<List<QueueEntry>> getFailedEntries(String homeId) {
    return dataSource.getFailedEntries(homeId);
  }

  @override
  Future<void> resetProcessingToPending(String homeId) {
    return dataSource.resetProcessingToPending(homeId);
  }
}
