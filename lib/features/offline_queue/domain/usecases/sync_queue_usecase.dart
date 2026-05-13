import 'dart:async';

import '../../data/repositories/offline_queue_repository.dart';
import '../../data/repositories/connectivity_repository.dart';
import '../entities/queue_entry.dart';
import '../entities/sync_status.dart';
import '../entities/action_type.dart';

class SyncQueueUseCase {
  final OfflineQueueRepository queueRepository;
  final ConnectivityRepository connectivityRepository;
  final Future<void> Function(QueueEntry entry) executeAction;

  SyncQueueUseCase({
    required this.queueRepository,
    required this.connectivityRepository,
    required this.executeAction,
  });

  Future<SyncResult> execute(String homeId) async {
    final status = await connectivityRepository.getCurrentStatus();
    if (status.isOffline) {
      return SyncResult(
        successCount: 0,
        failedCount: 0,
        conflicts: [],
      );
    }

    final pendingEntries = await queueRepository.getEntriesByHome(homeId);
    final entriesToSync =
        pendingEntries.where((e) => e.isPending).toList();

    int successCount = 0;
    int failedCount = 0;
    List<SyncConflict> conflicts = [];

    for (final entry in entriesToSync) {
      try {
        await queueRepository.updateEntryStatus(
          entryId: entry.id!,
          status: SyncStatus.syncing,
        );

        await executeAction(entry);

        await queueRepository.deleteEntry(entry.id!);
        successCount++;
      } catch (e) {
        final isConflict = _isConflictError(e);
        if (isConflict) {
          conflicts.add(SyncConflict(
            entryId: entry.id!,
            entityId: entry.entityId,
            actionType: entry.actionType,
            errorMessage: e.toString(),
          ));
          await queueRepository.deleteEntry(entry.id!);
        } else {
          await queueRepository.updateEntryStatus(
            entryId: entry.id!,
            status: SyncStatus.failed,
            errorMessage: e.toString(),
          );
          failedCount++;
        }
      }
    }

    return SyncResult(
      successCount: successCount,
      failedCount: failedCount,
      conflicts: conflicts,
    );
  }

  bool _isConflictError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('conflict') ||
        errorStr.contains('409') ||
        errorStr.contains('stale');
  }
}

class SyncResult {
  final int successCount;
  final int failedCount;
  final List<SyncConflict> conflicts;

  SyncResult({
    required this.successCount,
    required this.failedCount,
    required this.conflicts,
  });

  bool get hasResults => successCount > 0 || failedCount > 0 || conflicts.isNotEmpty;
  bool get allSucceeded => failedCount == 0 && conflicts.isEmpty;
}

class SyncConflict {
  final int entryId;
  final String entityId;
  final ActionType actionType;
  final String errorMessage;

  SyncConflict({
    required this.entryId,
    required this.entityId,
    required this.actionType,
    required this.errorMessage,
  });
}
