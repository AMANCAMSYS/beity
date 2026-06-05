import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../../core/local_database/app_database.dart';
import '../../../../core/local_database/local_database_service.dart';
import '../../../../core/services/local_cache_notifier.dart';
import '../../../../core/services/app_logger.dart';
import '../models/home_dashboard_snapshot.dart';

abstract class HomeDashboardSnapshotLocalDataSource {
  Future<void> saveSnapshot(HomeDashboardSnapshot snapshot);
  HomeDashboardSnapshot? getSnapshot(String homeId);
  Stream<HomeDashboardSnapshot?> watchSnapshot(String homeId);
}

class DriftHomeDashboardSnapshotLocalDataSource
    implements HomeDashboardSnapshotLocalDataSource {
  DriftHomeDashboardSnapshotLocalDataSource({AppDatabase? database})
    : _db = database ?? LocalDatabaseService.instance;

  final AppDatabase _db;
  final Map<String, HomeDashboardSnapshot> _memoryCache = {};

  String _getSnapshotKey(String homeId) => 'dashboard_snapshot:$homeId';

  @override
  Future<void> saveSnapshot(HomeDashboardSnapshot snapshot) async {
    try {
      final key = _getSnapshotKey(snapshot.homeId);
      final jsonStr = jsonEncode(snapshot.toJson());
      _memoryCache[snapshot.homeId] = snapshot;
      await _db
          .into(_db.localStoreMeta)
          .insertOnConflictUpdate(
            LocalStoreMetaCompanion(
              key: Value(key),
              value: Value(jsonStr),
              homeId: Value(snapshot.homeId),
              updatedAt: Value(DateTime.now()),
            ),
          );
      LocalCacheNotifier.notify(snapshot.homeId, 'dashboard_snapshot');
    } catch (e) {
      AppLogger.i('[DashboardSnapshot] saveSnapshot error: $e');
    }
  }

  @override
  HomeDashboardSnapshot? getSnapshot(String homeId) {
    return _memoryCache[homeId];
  }

  Future<HomeDashboardSnapshot?> _loadSnapshot(String homeId) async {
    try {
      final key = _getSnapshotKey(homeId);
      final row = await (_db.select(
        _db.localStoreMeta,
      )..where((tbl) => tbl.key.equals(key))).getSingleOrNull();
      if (row == null) return null;
      final json = jsonDecode(row.value) as Map<String, dynamic>;
      final snapshot = HomeDashboardSnapshot.fromJson(json);
      _memoryCache[homeId] = snapshot;
      return snapshot;
    } catch (e) {
      AppLogger.i('[DashboardSnapshot] _loadSnapshot error: $e');
      return null;
    }
  }

  @override
  Stream<HomeDashboardSnapshot?> watchSnapshot(String homeId) async* {
    yield getSnapshot(homeId) ?? await _loadSnapshot(homeId);

    await for (final event in LocalCacheNotifier.stream) {
      if (event.homeId == homeId && event.entityType == 'dashboard_snapshot') {
        yield getSnapshot(homeId) ?? await _loadSnapshot(homeId);
      }
    }
  }
}

final homeDashboardSnapshotDatasourceProvider =
    Provider<HomeDashboardSnapshotLocalDataSource>((ref) {
      return DriftHomeDashboardSnapshotLocalDataSource();
    });

final homeDashboardSnapshotProvider =
    StreamProvider.family<HomeDashboardSnapshot?, String>((ref, homeId) {
      if (homeId.isEmpty) return Stream.value(null);
      final datasource = ref.watch(homeDashboardSnapshotDatasourceProvider);
      return datasource.watchSnapshot(homeId);
    });

// A synchronous provider for zero-latency startup rendering
final cachedHomeDashboardSnapshotProvider =
    Provider.family<HomeDashboardSnapshot?, String>((ref, homeId) {
      if (homeId.isEmpty) return null;
      final datasource = ref.watch(homeDashboardSnapshotDatasourceProvider);

      // Watch the stream so this provider reactively updates
      ref.watch(homeDashboardSnapshotProvider(homeId));

      return datasource.getSnapshot(homeId);
    });
