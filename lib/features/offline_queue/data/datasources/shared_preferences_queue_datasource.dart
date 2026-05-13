import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/queue_entry.dart';
import '../../domain/entities/action_type.dart';
import '../../domain/entities/entity_type.dart';
import '../../domain/entities/sync_status.dart';

class SharedPreferencesQueueDataSource {
  static const String _queueKey = 'offline_queue_entries';

  Future<List<QueueEntry>> _loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_queueKey);
    if (json == null) return [];

    final List<dynamic> list = jsonDecode(json);
    return list.map((item) => QueueEntry.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> _saveEntries(List<QueueEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(_queueKey, json);
  }

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

  Future<List<QueueEntry>> getEntriesByHome(String homeId) async {
    final entries = await _loadEntries();
    return entries.where((e) => e.homeId == homeId).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<List<QueueEntry>> getEntriesByStatus(SyncStatus status) async {
    final entries = await _loadEntries();
    return entries.where((e) => e.syncStatus == status).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<int> getPendingCount(String homeId) async {
    final entries = await _loadEntries();
    return entries
        .where((e) => e.homeId == homeId && e.isPending)
        .length;
  }

  Future<QueueEntry?> getEntryById(int id) async {
    final entries = await _loadEntries();
    try {
      return entries.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

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

  Future<void> deleteEntry(int entryId) async {
    final entries = await _loadEntries();
    entries.removeWhere((e) => e.id == entryId);
    await _saveEntries(entries);
  }

  Future<void> deleteCompletedEntries(String homeId) async {
    final entries = await _loadEntries();
    entries.removeWhere((e) => e.homeId == homeId);
    await _saveEntries(entries);
  }

  Future<List<QueueEntry>> getFailedEntries(String homeId) async {
    final entries = await _loadEntries();
    return entries
        .where((e) => e.homeId == homeId && e.isFailed)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }
}
