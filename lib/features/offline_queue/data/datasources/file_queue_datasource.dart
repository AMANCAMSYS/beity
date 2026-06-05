import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sawa/core/services/shared_prefs_provider.dart';
import 'package:sawa/core/services/supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/action_type.dart';
import '../../domain/entities/entity_type.dart';
import '../../domain/entities/queue_entry.dart';
import '../../domain/entities/sync_status.dart';
import 'queue_datasource.dart';

class FileQueueDataSource implements QueueDataSource {
  static const String _legacyQueueKeyBase = 'offline_queue_entries';
  static const String _queueDirectoryName = 'offline_queue';
  static const String _entriesDirectoryName = 'entries';
  static const int _storageVersion = 2;

  static final Map<String, Future<void>> _locks = {};

  final Future<Directory> Function()? _baseDirectoryProvider;
  final SharedPreferences? _legacyPrefs;
  final String Function() _userIdProvider;
  final DateTime Function() _now;
  final Set<String> _migratedUsers = {};

  FileQueueDataSource({
    Future<Directory> Function()? baseDirectoryProvider,
    SharedPreferences? legacyPrefs,
    String Function()? userIdProvider,
    DateTime Function()? now,
  }) : _baseDirectoryProvider = baseDirectoryProvider,
       _legacyPrefs = legacyPrefs,
       _now = now ?? DateTime.now,
       _userIdProvider =
           userIdProvider ??
           (() {
             final user = SupabaseService.client.auth.currentUser;
             return user?.id ?? 'anonymous';
           });

  String get _userId => _userIdProvider();

  Future<T> _exclusiveForUser<T>(String userId, Future<T> Function() action) {
    final lockKey = userId;
    final previous = _locks[lockKey] ?? Future<void>.value();
    final next = previous.then((_) => action(), onError: (_) => action());
    _locks[lockKey] = next.then((_) {}, onError: (_) {});
    return next;
  }

  Future<Directory> _queueRootDirectory() async {
    final baseDirectory = _baseDirectoryProvider != null
        ? await _baseDirectoryProvider()
        : await getApplicationSupportDirectory();
    final directory = Directory(
      '${baseDirectory.path}${Platform.pathSeparator}$_queueDirectoryName',
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  String _safeFileName(String value) {
    return value.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  }

  Future<Directory> _userDirectory(String userId) async {
    final root = await _queueRootDirectory();
    return Directory(
      '${root.path}${Platform.pathSeparator}${_safeFileName(userId)}',
    );
  }

  Future<Directory> _entriesDirectory(String userId) async {
    final userDirectory = await _userDirectory(userId);
    final directory = Directory(
      '${userDirectory.path}${Platform.pathSeparator}$_entriesDirectoryName',
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<File> _entryFileForId(String userId, int entryId) async {
    final directory = await _entriesDirectory(userId);
    return File(
      '${directory.path}${Platform.pathSeparator}${_safeFileName(entryId.toString())}.json',
    );
  }

  Future<File> _legacyAggregateFileForUser(String userId) async {
    final root = await _queueRootDirectory();
    return File(
      '${root.path}${Platform.pathSeparator}${_safeFileName(userId)}.json',
    );
  }

  Future<SharedPreferences> _prefs() async {
    if (_legacyPrefs != null) return _legacyPrefs;
    try {
      return AppPreferences.instance;
    } catch (_) {
      return SharedPreferences.getInstance();
    }
  }

  String _legacyQueueKey(String userId) => '${userId}_$_legacyQueueKeyBase';

  Future<void> _migrateLegacyQueueIfNeeded(String userId) async {
    if (_migratedUsers.contains(userId)) return;
    _migratedUsers.add(userId);

    final existingIds = (await _loadEntryFiles(userId))
        .map(
          (file) => int.tryParse(file.uri.pathSegments.last.split('.').first),
        )
        .whereType<int>()
        .toSet();

    final legacyEntries = <QueueEntry>[];
    final aggregateFile = await _legacyAggregateFileForUser(userId);
    if (await aggregateFile.exists()) {
      try {
        legacyEntries.addAll(
          _decodeEntries(await aggregateFile.readAsString()),
        );
      } on FormatException {
        await _backupCorruptFile(aggregateFile);
      }
    }

    final prefs = await _prefs();
    final legacyJson = prefs.getString(_legacyQueueKey(userId));
    if (legacyJson != null && legacyJson.isNotEmpty) {
      legacyEntries.addAll(_decodeEntries(legacyJson));
    }

    for (final entry in legacyEntries) {
      final id = entry.id ?? await _nextEntryIdForUser(userId);
      if (existingIds.add(id)) {
        await _saveEntryForUser(userId, entry.copyWith(id: id));
      }
    }

    if (await aggregateFile.exists()) {
      await aggregateFile.delete();
    }
    await prefs.remove(_legacyQueueKey(userId));
  }

  List<QueueEntry> _decodeEntries(String content) {
    if (content.trim().isEmpty) return [];

    final decoded = jsonDecode(content);
    final rawEntries = decoded is List
        ? decoded
        : (decoded as Map<String, dynamic>)['entries'] as List<dynamic>;

    return rawEntries
        .map((item) => QueueEntry.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<File>> _loadEntryFiles(String userId) async {
    final directory = await _entriesDirectory(userId);
    final entities = await directory.list().toList();
    return entities
        .whereType<File>()
        .where((file) => file.path.endsWith('.json'))
        .toList();
  }

  Future<List<QueueEntry>> _loadEntriesForUser(String userId) async {
    await _migrateLegacyQueueIfNeeded(userId);
    final files = await _loadEntryFiles(userId);
    final entries = <QueueEntry>[];

    for (final file in files) {
      try {
        final content = await file.readAsString();
        if (content.trim().isEmpty) continue;
        final decoded = jsonDecode(content) as Map<String, dynamic>;
        final entryJson =
            (decoded['entry'] as Map<String, dynamic>?) ?? decoded;
        entries.add(QueueEntry.fromJson(entryJson));
      } on FormatException {
        await _backupCorruptFile(file);
      }
    }

    entries.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return entries;
  }

  Future<QueueEntry?> _loadEntryForUser(String userId, int entryId) async {
    await _migrateLegacyQueueIfNeeded(userId);
    final file = await _entryFileForId(userId, entryId);
    if (!await file.exists()) return null;

    try {
      final decoded = jsonDecode(await file.readAsString());
      final entryJson = decoded is Map<String, dynamic>
          ? (decoded['entry'] as Map<String, dynamic>?) ?? decoded
          : null;
      if (entryJson == null) return null;
      return QueueEntry.fromJson(entryJson);
    } on FormatException {
      await _backupCorruptFile(file);
      return null;
    }
  }

  Future<void> _backupCorruptFile(File file) async {
    if (!await file.exists()) return;

    final backup = File(
      '${file.path}.corrupt.${_now().microsecondsSinceEpoch}',
    );
    await file.rename(backup.path);
  }

  Future<int> _nextEntryIdForUser(String userId) async {
    var candidate = _now().microsecondsSinceEpoch;
    while (await (await _entryFileForId(userId, candidate)).exists()) {
      candidate++;
    }
    return candidate;
  }

  Future<void> _saveEntryForUser(String userId, QueueEntry entry) async {
    final id = entry.id;
    if (id == null) return;

    final file = await _entryFileForId(userId, id);
    final tempFile = File('${file.path}.tmp.${_now().microsecondsSinceEpoch}');
    final content = jsonEncode({
      'version': _storageVersion,
      'userId': userId,
      'entry': entry.toJson(),
    });

    await tempFile.writeAsString(content, flush: true);
    if (await file.exists()) {
      await file.delete();
    }
    await tempFile.rename(file.path);
  }

  @override
  Future<void> clearQueue() {
    final userId = _userId;
    return _exclusiveForUser(userId, () => _clearQueueForUserUnlocked(userId));
  }

  @override
  Future<void> clearQueueForUser(String userId) {
    return _exclusiveForUser(userId, () => _clearQueueForUserUnlocked(userId));
  }

  Future<void> _clearQueueForUserUnlocked(String userId) async {
    final userDirectory = await _userDirectory(userId);
    if (await userDirectory.exists()) {
      await userDirectory.delete(recursive: true);
    }

    final aggregateFile = await _legacyAggregateFileForUser(userId);
    if (await aggregateFile.exists()) {
      await aggregateFile.delete();
    }

    final prefs = await _prefs();
    await prefs.remove(_legacyQueueKey(userId));
    _migratedUsers.remove(userId);
  }

  @override
  Future<int> enqueueAction({
    required ActionType actionType,
    required EntityType entityType,
    required String entityId,
    String? homeId,
    MutationScope scope = MutationScope.home,
    required Map<String, dynamic> payload,
  }) {
    final userId = _userId;
    return _exclusiveForUser(userId, () async {
      await _migrateLegacyQueueIfNeeded(userId);
      final now = _now();
      final id = await _nextEntryIdForUser(userId);
      final newEntry = QueueEntry(
        id: id,
        actionType: actionType,
        entityType: entityType,
        entityId: entityId,
        homeId: homeId,
        scope: scope,
        payload: payload,
        createdAt: now,
        syncStatus: SyncStatus.pending,
      );

      await _saveEntryForUser(userId, newEntry);
      return newEntry.id!;
    });
  }

  @override
  Future<List<QueueEntry>> getEntriesByHome(String homeId) {
    final userId = _userId;
    return _exclusiveForUser(userId, () async {
      final entries = await _loadEntriesForUser(userId);
      return entries
          .where(
            (entry) =>
                entry.homeId == homeId && entry.scope == MutationScope.home,
          )
          .toList();
    });
  }

  @override
  Future<List<QueueEntry>> getEntriesByStatus(SyncStatus status) {
    final userId = _userId;
    return _exclusiveForUser(userId, () async {
      final entries = await _loadEntriesForUser(userId);
      return entries.where((entry) => entry.syncStatus == status).toList();
    });
  }

  @override
  Future<int> getPendingCount(String homeId) {
    final userId = _userId;
    return _exclusiveForUser(userId, () async {
      final entries = await _loadEntriesForUser(userId);
      return entries
          .where((entry) => entry.homeId == homeId && entry.isPending)
          .where((entry) => entry.scope == MutationScope.home)
          .length;
    });
  }

  @override
  Future<List<QueueEntry>> getEntriesByUserScope(String userId) {
    return _exclusiveForUser(userId, () async {
      final entries = await _loadEntriesForUser(userId);
      return entries
          .where(
            (entry) =>
                entry.scope == MutationScope.user && _isSyncableStatus(entry),
          )
          .toList();
    });
  }

  @override
  Future<List<QueueEntry>> getEntriesByGlobalScope() {
    final userId = _userId;
    return _exclusiveForUser(userId, () async {
      final entries = await _loadEntriesForUser(userId);
      return entries
          .where(
            (entry) =>
                entry.scope == MutationScope.global && _isSyncableStatus(entry),
          )
          .toList();
    });
  }

  @override
  Future<int> getPendingCountForUser(String userId) {
    return _exclusiveForUser(userId, () async {
      final entries = await _loadEntriesForUser(userId);
      return entries
          .where(
            (entry) =>
                entry.isPending &&
                (entry.scope == MutationScope.user ||
                    entry.scope == MutationScope.global),
          )
          .length;
    });
  }

  @override
  Future<QueueEntry?> getEntryById(int id) {
    final userId = _userId;
    return _exclusiveForUser(userId, () => _loadEntryForUser(userId, id));
  }

  @override
  Future<void> updateEntryStatus({
    required int entryId,
    required SyncStatus status,
    String? errorMessage,
  }) {
    final userId = _userId;
    return _exclusiveForUser(userId, () async {
      final entry = await _loadEntryForUser(userId, entryId);
      if (entry == null) return;

      final updatedEntry = entry.copyWith(
        syncStatus: status,
        retryCount: status == SyncStatus.failed
            ? entry.retryCount + 1
            : entry.retryCount,
        lastRetryAt: status == SyncStatus.syncing ? _now() : null,
        errorMessage: errorMessage,
      );

      await _saveEntryForUser(userId, updatedEntry);
    });
  }

  @override
  Future<void> deleteEntry(int entryId) {
    final userId = _userId;
    return _exclusiveForUser(userId, () async {
      await _migrateLegacyQueueIfNeeded(userId);
      final file = await _entryFileForId(userId, entryId);
      if (await file.exists()) {
        await file.delete();
      }
    });
  }

  @override
  Future<void> deleteCompletedEntries(String homeId) {
    final userId = _userId;
    return _exclusiveForUser(userId, () async {
      final entries = await _loadEntriesForUser(userId);
      for (final entry in entries) {
        if (entry.homeId == homeId &&
            entry.scope == MutationScope.home &&
            entry.id != null) {
          final file = await _entryFileForId(userId, entry.id!);
          if (await file.exists()) {
            await file.delete();
          }
        }
      }
    });
  }

  @override
  Future<List<QueueEntry>> getFailedEntries(String homeId) {
    final userId = _userId;
    return _exclusiveForUser(userId, () async {
      final entries = await _loadEntriesForUser(userId);
      return entries
          .where(
            (entry) =>
                entry.homeId == homeId &&
                entry.scope == MutationScope.home &&
                entry.isFailed,
          )
          .toList();
    });
  }

  @override
  Future<void> resetProcessingToPending(String homeId) {
    final userId = _userId;
    return _exclusiveForUser(userId, () async {
      final entries = await _loadEntriesForUser(userId);
      for (final entry in entries) {
        if (entry.homeId == homeId &&
            entry.scope == MutationScope.home &&
            entry.syncStatus == SyncStatus.syncing &&
            entry.id != null) {
          await _saveEntryForUser(
            userId,
            entry.copyWith(syncStatus: SyncStatus.pending),
          );
        }
      }
    });
  }

  @override
  Future<void> resetProcessingToPendingForUserScope(String userId) {
    return _exclusiveForUser(userId, () async {
      final entries = await _loadEntriesForUser(userId);
      for (final entry in entries) {
        final isUserScoped =
            entry.scope == MutationScope.user ||
            entry.scope == MutationScope.global;
        if (isUserScoped &&
            entry.syncStatus == SyncStatus.syncing &&
            entry.id != null) {
          await _saveEntryForUser(
            userId,
            entry.copyWith(syncStatus: SyncStatus.pending),
          );
        }
      }
    });
  }

  bool _isSyncableStatus(QueueEntry entry) {
    return entry.isPending || entry.isSyncing || entry.isFailed;
  }
}
