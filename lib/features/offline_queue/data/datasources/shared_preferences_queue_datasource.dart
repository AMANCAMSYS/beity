import 'dart:convert';
import 'package:beity/core/services/supabase_service.dart';
import 'package:beity/core/services/shared_prefs_provider.dart';


import '../../domain/entities/queue_entry.dart';
import '../../domain/entities/action_type.dart';
import '../../domain/entities/entity_type.dart';
import '../../domain/entities/sync_status.dart';

import 'queue_datasource.dart';

class SharedPreferencesQueueDataSource implements QueueDataSource {
  static const String _queueKeyBase = 'offline_queue_entries';

  String _getUserId() {
    final user = SupabaseService.client.auth.currentUser;
    return user?.id ?? 'anonymous';
  }

  String get _queueKey => '${_getUserId()}_$_queueKeyBase';

  Future<List<QueueEntry>> _loadEntries() async {
    final prefs = AppPreferences.instance;
    final json = prefs.getString(_queueKey);
    if (json == null) return [];

    final List<dynamic> list = jsonDecode(json);
    return list.map((item) => QueueEntry.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> _saveEntries(List<QueueEntry> entries) async {
    final prefs = AppPreferences.instance;
    final json = jsonEncode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(_queueKey, json);
  }

  @override
  Future<void> clearQueue() async {
    final prefs = AppPreferences.instance;
    await prefs.remove(_queueKey);
  }

  @override
  Future<void> clearQueueForUser(String userId) async {
    final prefs = AppPreferences.instance;
    await prefs.remove('${userId}_$_queueKeyBase');
  }

  @override
  Future<int> enqueueAction({
    required ActionType actionType,
    required EntityType entityType,
    required String entityId,
    required String homeId,
    required Map<String, dynamic> payload,
  }) async {
    final entries = await _loadEntries();
    final newEntry = QueueEntry(
      id: DateTime.now().millisecondsSinceEpoch,
      actionType: actionType,
      entityType: entityType,
      entityId: entityId,
      homeId: homeId,
      payload: payload,
      createdAt: DateTime.now(),
      syncStatus: SyncStatus.pending,
    );

    entries.add(newEntry);
    await _saveEntries(entries);
    return newEntry.id!;
  }

  @override
  Future<List<QueueEntry>> getEntriesByHome(String homeId) async {
    final entries = await _loadEntries();
    return entries.where((e) => e.homeId == homeId).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  @override
  Future<List<QueueEntry>> getEntriesByStatus(SyncStatus status) async {
    final entries = await _loadEntries();
    return entries.where((e) => e.syncStatus == status).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  @override
  Future<int> getPendingCount(String homeId) async {
    final entries = await _loadEntries();
    return entries
        .where((e) => e.homeId == homeId && e.isPending)
        .length;
  }

  @override
  Future<QueueEntry?> getEntryById(int id) async {
    final entries = await _loadEntries();
    try {
      return entries.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> updateEntryStatus({
    required int entryId,
    required SyncStatus status,
    String? errorMessage,
  }) async {
    final entries = await _loadEntries();
    final index = entries.indexWhere((e) => e.id == entryId);
    if (index == -1) return;

    entries[index] = entries[index].copyWith(
      syncStatus: status,
      retryCount: status == SyncStatus.failed
          ? entries[index].retryCount + 1
          : entries[index].retryCount,
      lastRetryAt: status == SyncStatus.syncing ? DateTime.now() : null,
      errorMessage: errorMessage,
    );

    await _saveEntries(entries);
  }

  @override
  Future<void> deleteEntry(int entryId) async {
    final entries = await _loadEntries();
    entries.removeWhere((e) => e.id == entryId);
    await _saveEntries(entries);
  }

  @override
  Future<void> deleteCompletedEntries(String homeId) async {
    final entries = await _loadEntries();
    entries.removeWhere((e) => e.homeId == homeId);
    await _saveEntries(entries);
  }

  @override
  Future<List<QueueEntry>> getFailedEntries(String homeId) async {
    final entries = await _loadEntries();
    return entries
        .where((e) => e.homeId == homeId && e.isFailed)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  @override
  Future<void> resetProcessingToPending(String homeId) async {
    final entries = await _loadEntries();
    bool updated = false;
    for (int i = 0; i < entries.length; i++) {
      if (entries[i].homeId == homeId && entries[i].syncStatus == SyncStatus.syncing) {
        entries[i] = entries[i].copyWith(syncStatus: SyncStatus.pending);
        updated = true;
      }
    }
    if (updated) {
      await _saveEntries(entries);
    }
  }
}
