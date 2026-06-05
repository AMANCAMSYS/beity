import 'dart:async';
import 'package:sawa/core/services/sync_service.dart';
import '../../data/repositories/offline_queue_repository.dart';
import '../../data/repositories/connectivity_repository.dart';
import '../entities/queue_entry.dart';
import '../entities/sync_status.dart';
import '../entities/action_type.dart';

class SyncQueueUseCase {
  final OfflineQueueRepository queueRepository;
  final ConnectivityRepository connectivityRepository;
  final SyncService? syncService;
  final Future<String?> Function(QueueEntry entry) executeAction;
  final Future<bool> Function()? checkCanSyncNow;
  final bool useCompaction;
  final SyncQueueLock syncLock;

  SyncQueueUseCase({
    required this.queueRepository,
    required this.connectivityRepository,
    required this.executeAction,
    this.checkCanSyncNow,
    this.syncService,
    this.useCompaction = true,
    SyncQueueLock? syncLock,
  }) : syncLock = syncLock ?? SyncQueueLock();

  // Outbox Queue Compaction Logic
  List<QueueEntry> compactQueue(List<QueueEntry> entries) {
    if (entries.isEmpty) return [];

    // Group entries by entityId to compact operations per item
    final Map<String, List<QueueEntry>> groupedByEntity = {};
    for (final entry in entries) {
      groupedByEntity.putIfAbsent(entry.entityId, () => []).add(entry);
    }

    final List<QueueEntry> compactedEntries = [];

    groupedByEntity.forEach((entityId, entityEntries) {
      // Sort chronologically to maintain history order
      entityEntries.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      List<QueueEntry> compactedForEntity = [];

      for (final entry in entityEntries) {
        if (compactedForEntity.isEmpty) {
          compactedForEntity.add(entry);
          continue;
        }

        final lastEntry = compactedForEntity.last;

        // Rule 1: create (addItem) then delete (deleteItem) -> If never synced, discard both!
        if (lastEntry.actionType == ActionType.addItem &&
            entry.actionType == ActionType.deleteItem) {
          compactedForEntity.removeLast();
          continue;
        }

        // Rule 2: update then delete for an item existing on server -> compact to delete only!
        if ((lastEntry.actionType == ActionType.updateItem ||
                lastEntry.actionType == ActionType.updateQuantity ||
                lastEntry.actionType == ActionType.markPurchased) &&
            entry.actionType == ActionType.deleteItem) {
          final isLocalCreation = entityEntries.any(
            (e) => e.actionType == ActionType.addItem,
          );
          if (!isLocalCreation) {
            compactedForEntity.clear();
            compactedForEntity.add(entry);
          } else {
            // Created locally and deleted before sync -> Discard everything
            compactedForEntity.clear();
          }
          continue;
        }

        // Rule 3: create (addItem) then update -> compact to single create (addItem) with merged payload!
        if (lastEntry.actionType == ActionType.addItem &&
            (entry.actionType == ActionType.updateItem ||
                entry.actionType == ActionType.updateQuantity ||
                entry.actionType == ActionType.markPurchased)) {
          final mergedPayload = Map<String, dynamic>.from(lastEntry.payload)
            ..addAll(entry.payload);
          compactedForEntity[compactedForEntity.length - 1] = lastEntry
              .copyWith(payload: mergedPayload);
          continue;
        }

        // Rule 4: multiple updates -> compact to single update!
        if ((lastEntry.actionType == ActionType.updateItem ||
                lastEntry.actionType == ActionType.updateQuantity ||
                lastEntry.actionType == ActionType.markPurchased) &&
            (entry.actionType == ActionType.updateItem ||
                entry.actionType == ActionType.updateQuantity ||
                entry.actionType == ActionType.markPurchased)) {
          final mergedPayload = Map<String, dynamic>.from(lastEntry.payload)
            ..addAll(entry.payload);
          final hasOtherUpdates = mergedPayload.keys.any(
            (k) =>
                k != 'status' &&
                k != 'completed_at' &&
                k != 'completed_by' &&
                k != 'id' &&
                k != 'list_id',
          );
          final finalActionType =
              (entry.actionType == ActionType.markPurchased && !hasOtherUpdates)
              ? ActionType.markPurchased
              : ActionType.updateItem;

          compactedForEntity[compactedForEntity.length - 1] = lastEntry
              .copyWith(actionType: finalActionType, payload: mergedPayload);
          continue;
        }

        // Default: append
        compactedForEntity.add(entry);
      }

      compactedEntries.addAll(compactedForEntity);
    });

    // Re-sort chronologically by original creation time to preserve relational dependency order
    compactedEntries.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return compactedEntries;
  }

  Future<SyncResult> execute(String homeId) async {
    // 1. Prevent duplicate sync runs for the same home only.
    if (!syncLock.tryAcquire(homeId)) {
      return SyncResult(successCount: 0, failedCount: 0, conflicts: []);
    }

    try {
      if (checkCanSyncNow != null) {
        final canSync = await checkCanSyncNow!();
        if (!canSync) {
          return SyncResult(successCount: 0, failedCount: 0, conflicts: []);
        }
      } else {
        final status = await connectivityRepository.getCurrentStatus();
        if (status.isOffline) {
          return SyncResult(successCount: 0, failedCount: 0, conflicts: []);
        }
      }

      // 2. Crash Recovery: Reset any stuck 'processing' (syncing) statuses back to 'pending'
      await queueRepository.resetProcessingToPending(homeId);

      // Load pending and retriable failed entries
      final now = DateTime.now();
      final pendingEntries = await queueRepository.getEntriesByHome(homeId);
      final entriesToSync = pendingEntries.where((e) {
        if (e.isPending) return true;
        if (e.isFailed) {
          final isPermanent = e.errorMessage?.startsWith('PERMANENT') ?? false;
          final isConflict = e.errorMessage?.startsWith('CONFLICT') ?? false;
          final retryDue =
              e.lastRetryAt == null || !e.lastRetryAt!.isAfter(now);
          return e.retryCount < QueueEntry.maxRetries &&
              !isPermanent &&
              !isConflict &&
              retryDue;
        }
        return false;
      }).toList();

      if (entriesToSync.isEmpty) {
        return SyncResult(successCount: 0, failedCount: 0, conflicts: []);
      }

      // 3. Queue Compaction: Minimize redundant server calls safely
      final compactedList = useCompaction
          ? compactQueue(entriesToSync)
          : entriesToSync;

      int successCount = 0;
      int failedCount = 0;
      List<SyncConflict> conflicts = [];
      final Map<String, String> idMappings = {};

      for (final entry in compactedList) {
        try {
          await queueRepository.updateEntryStatus(
            entryId: entry.id!,
            status: SyncStatus.syncing,
          );

          // Pre-process entry to resolve any temporary IDs
          QueueEntry effectiveEntry = entry;

          if (idMappings.containsKey(entry.entityId)) {
            final realId = idMappings[entry.entityId]!;
            effectiveEntry = effectiveEntry.copyWith(entityId: realId);
          }

          if (effectiveEntry.payload.isNotEmpty) {
            final updatedPayload = Map<String, dynamic>.from(
              effectiveEntry.payload,
            );
            bool payloadUpdated = false;
            updatedPayload.forEach((key, value) {
              if (value is String && idMappings.containsKey(value)) {
                updatedPayload[key] = idMappings[value];
                payloadUpdated = true;
              }
            });
            if (payloadUpdated) {
              effectiveEntry = effectiveEntry.copyWith(payload: updatedPayload);
            }
          }

          final realId = await executeAction(effectiveEntry);

          if (realId != null && realId != entry.entityId) {
            idMappings[entry.entityId] = realId;
          }

          // Delete from local outbox upon successful server write
          await queueRepository.deleteEntry(entry.id!);
          successCount++;
        } catch (e) {
          final isConflict = _isConflictError(e);
          final isPermanent = _isPermanentError(e);

          if (isConflict) {
            conflicts.add(
              SyncConflict(
                entryId: entry.id!,
                entityId: entry.entityId,
                actionType: entry.actionType,
                errorMessage: e.toString(),
              ),
            );
            await queueRepository.updateEntryStatus(
              entryId: entry.id!,
              status: SyncStatus.failed,
              errorMessage: 'CONFLICT: ${e.toString()}',
            );
            failedCount++;
          } else if (isPermanent) {
            // Permanent error (e.g. 400 Bad Request, 401/403 Unauthorized, validation fail)
            // Mark as failed permanent, store error, and do not retry automatically
            await queueRepository.updateEntryStatus(
              entryId: entry.id!,
              status: SyncStatus.failed,
              errorMessage: 'PERMANENT: ${e.toString()}',
            );
            failedCount++;
          } else {
            // Temporary error (e.g. Network offline, Timeout, 5xx server error)
            // Keep in queue for retry, increment retryCount
            await queueRepository.updateEntryStatus(
              entryId: entry.id!,
              status: SyncStatus.failed,
              errorMessage: e.toString(),
            );
            failedCount++;
          }
        }
      }

      // 4. Pull After Push: Bypassed to allow efficient delta sync instead of full fresh pull
      // UUIDs generated on the client are persistent; we will trigger a Delta Sync on the affected tables.

      return SyncResult(
        successCount: successCount,
        failedCount: failedCount,
        conflicts: conflicts,
      );
    } finally {
      syncLock.release(homeId);
    }
  }

  Future<SyncResult> executeUserScope(String userId) async {
    const lockKey = 'user_scope';

    if (!syncLock.tryAcquire(lockKey)) {
      return SyncResult(successCount: 0, failedCount: 0, conflicts: []);
    }

    try {
      if (checkCanSyncNow != null) {
        final canSync = await checkCanSyncNow!();
        if (!canSync) {
          return SyncResult(successCount: 0, failedCount: 0, conflicts: []);
        }
      } else {
        final status = await connectivityRepository.getCurrentStatus();
        if (status.isOffline) {
          return SyncResult(successCount: 0, failedCount: 0, conflicts: []);
        }
      }

      final now = DateTime.now();
      await queueRepository.resetProcessingToPendingForUserScope(userId);
      final pendingEntries = await queueRepository.getEntriesByUserScope(
        userId,
      );
      final globalEntries = await queueRepository.getEntriesByGlobalScope();
      final allEntries = [...pendingEntries, ...globalEntries];

      final entriesToSync = allEntries.where((e) {
        if (e.isPending) return true;
        if (e.isFailed) {
          final isPermanent = e.errorMessage?.startsWith('PERMANENT') ?? false;
          final isConflict = e.errorMessage?.startsWith('CONFLICT') ?? false;
          final retryDue =
              e.lastRetryAt == null || !e.lastRetryAt!.isAfter(now);
          return e.retryCount < QueueEntry.maxRetries &&
              !isPermanent &&
              !isConflict &&
              retryDue;
        }
        return false;
      }).toList();

      if (entriesToSync.isEmpty) {
        return SyncResult(successCount: 0, failedCount: 0, conflicts: []);
      }

      final compactedList = useCompaction
          ? compactQueue(entriesToSync)
          : entriesToSync;

      int successCount = 0;
      int failedCount = 0;
      List<SyncConflict> conflicts = [];

      for (final entry in compactedList) {
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
          final isPermanent = _isPermanentError(e);

          if (isConflict) {
            conflicts.add(
              SyncConflict(
                entryId: entry.id!,
                entityId: entry.entityId,
                actionType: entry.actionType,
                errorMessage: e.toString(),
              ),
            );
            await queueRepository.updateEntryStatus(
              entryId: entry.id!,
              status: SyncStatus.failed,
              errorMessage: 'CONFLICT: ${e.toString()}',
            );
            failedCount++;
          } else if (isPermanent) {
            await queueRepository.updateEntryStatus(
              entryId: entry.id!,
              status: SyncStatus.failed,
              errorMessage: 'PERMANENT: ${e.toString()}',
            );
            failedCount++;
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
    } finally {
      syncLock.release(lockKey);
    }
  }

  bool _isConflictError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('conflict') ||
        errorStr.contains('409') ||
        errorStr.contains('stale');
  }

  bool _isPermanentError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    // HTTP Status codes:
    // 400 Bad Request, 401 Unauthorized, 403 Forbidden, 422 Unprocessable (validation)
    return errorStr.contains('400') ||
        errorStr.contains('401') ||
        errorStr.contains('403') ||
        errorStr.contains('422') ||
        errorStr.contains('permission denied') ||
        errorStr.contains('permission_denied') ||
        errorStr.contains('violates') ||
        errorStr.contains('validation') ||
        errorStr.contains('bad request') ||
        errorStr.contains('syntax error');
  }
}

class SyncQueueLock {
  final Set<String> _activeKeys = {};

  bool tryAcquire(String key) {
    if (_activeKeys.contains(key)) return false;
    _activeKeys.add(key);
    return true;
  }

  void release(String key) {
    _activeKeys.remove(key);
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

  bool get hasResults =>
      successCount > 0 || failedCount > 0 || conflicts.isNotEmpty;
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
