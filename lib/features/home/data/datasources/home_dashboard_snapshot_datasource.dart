import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/shared_prefs_provider.dart';
import '../../../../core/services/local_cache_notifier.dart';
import '../models/home_dashboard_snapshot.dart';

abstract class HomeDashboardSnapshotLocalDataSource {
  Future<void> saveSnapshot(HomeDashboardSnapshot snapshot);
  HomeDashboardSnapshot? getSnapshot(String homeId);
  Stream<HomeDashboardSnapshot?> watchSnapshot(String homeId);
}

class SharedPreferencesHomeDashboardSnapshotLocalDataSource
    implements HomeDashboardSnapshotLocalDataSource {
  String _getSnapshotKey(String homeId) => 'cached_home_dashboard_snapshot_$homeId';

  @override
  Future<void> saveSnapshot(HomeDashboardSnapshot snapshot) async {
    try {
      final prefs = AppPreferences.instance;
      final key = _getSnapshotKey(snapshot.homeId);
      final jsonStr = jsonEncode(snapshot.toJson());
      await prefs.setString(key, jsonStr);
      LocalCacheNotifier.notify(snapshot.homeId, 'dashboard_snapshot');
    } catch (e, stack) {
      assert(() {
        print('SharedPreferencesHomeDashboardSnapshotLocalDataSource.saveSnapshot error: $e\n$stack');
        return true;
      }());
    }
  }

  @override
  HomeDashboardSnapshot? getSnapshot(String homeId) {
    try {
      final prefs = AppPreferences.instance;
      final key = _getSnapshotKey(homeId);
      final jsonStr = prefs.getString(key);
      if (jsonStr == null) return null;
      final Map<String, dynamic> json = jsonDecode(jsonStr);
      return HomeDashboardSnapshot.fromJson(json);
    } catch (e, stack) {
      assert(() {
        print('SharedPreferencesHomeDashboardSnapshotLocalDataSource.getSnapshot error: $e\n$stack');
        return true;
      }());
      return null;
    }
  }

  @override
  Stream<HomeDashboardSnapshot?> watchSnapshot(String homeId) async* {
    yield getSnapshot(homeId);

    await for (final event in LocalCacheNotifier.stream) {
      if (event.homeId == homeId && event.entityType == 'dashboard_snapshot') {
        yield getSnapshot(homeId);
      }
    }
  }
}

final homeDashboardSnapshotDatasourceProvider =
    Provider<HomeDashboardSnapshotLocalDataSource>((ref) {
  return SharedPreferencesHomeDashboardSnapshotLocalDataSource();
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
