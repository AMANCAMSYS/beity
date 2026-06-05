import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sawa/core/local_database/daos/sync_dao.dart';
import 'package:sawa/core/local_database/local_database_service.dart';
import 'shared_prefs_provider.dart';
import 'app_logger.dart';
import 'supabase_service.dart';

class SyncService {
  final SupabaseClient _client;
  final SyncDao _syncDao;

  SyncService(this._client, [SyncDao? syncDao])
    : _syncDao = syncDao ?? SyncDao(LocalDatabaseService.instance);

  // Storage keys generator
  String _getSyncKey(String homeId, String entityType) =>
      'sync_ts_${homeId}_$entityType';
  String _getCacheKey(String homeId, String entityType) =>
      'sync_cache_${homeId}_$entityType';

  // Get last local sync time
  DateTime getLocalSyncTime(String homeId, String entityType) {
    try {
      final prefs = AppPreferences.instance;
      final tsStr = prefs.getString(_getSyncKey(homeId, entityType));
      if (tsStr == null) return DateTime.fromMillisecondsSinceEpoch(0);
      return DateTime.parse(tsStr);
    } catch (e) {
      AppLogger.i('[SyncService] Failed to read local sync time: $e');
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  Future<DateTime> getLocalSyncTimeAsync(
    String homeId,
    String entityType,
  ) async {
    final driftTime = await _syncDao.getLocalSyncTime(homeId, entityType);
    if (driftTime.isAfter(DateTime.fromMillisecondsSinceEpoch(0))) {
      return driftTime;
    }
    return getLocalSyncTime(homeId, entityType);
  }

  // Update local sync time
  Future<void> updateLocalSyncTime(
    String homeId,
    String entityType,
    DateTime time,
  ) async {
    try {
      final prefs = AppPreferences.instance;
      await prefs.setString(
        _getSyncKey(homeId, entityType),
        time.toIso8601String(),
      );
    } catch (e) {
      AppLogger.i(
        '[SyncService] Failed to persist sync time to preferences: $e',
      );
    }

    try {
      await _syncDao.updateLocalSyncTime(homeId, entityType, time);
    } catch (e) {
      AppLogger.i('[SyncService] Failed to persist sync time to Drift: $e');
    }
  }

  Future<void> resetLocalSyncTime(String homeId, String entityType) async {
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    try {
      final prefs = AppPreferences.instance;
      await prefs.setString(
        _getSyncKey(homeId, entityType),
        epoch.toIso8601String(),
      );
    } catch (e) {
      AppLogger.i('[SyncService] Failed to reset sync time in preferences: $e');
    }

    try {
      await _syncDao.resetLocalSyncTime(homeId, entityType);
    } catch (e) {
      AppLogger.i('[SyncService] Failed to reset sync time in Drift: $e');
    }
  }

  Future<void> resetLocalSyncTimes(
    String homeId,
    Iterable<String> entityTypes,
  ) async {
    for (final entityType in entityTypes) {
      await resetLocalSyncTime(homeId, entityType);
    }
  }

  Future<bool> isInitialSyncDone(String homeId, String entityType) {
    return _syncDao.isInitialSyncDone(homeId, entityType);
  }

  Future<void> markInitialSyncDone(String homeId, String entityType) {
    return _syncDao.markInitialSyncDone(homeId, entityType);
  }

  // Save local data cache helper
  Future<void> cacheData(String homeId, String entityType, dynamic data) async {
    try {
      final prefs = AppPreferences.instance;
      await prefs.setString(_getCacheKey(homeId, entityType), jsonEncode(data));
    } catch (e) {
      AppLogger.i('[SyncService] Failed to cache $entityType data: $e');
    }
  }

  // Retrieve local data cache helper
  dynamic getCachedData(String homeId, String entityType) {
    try {
      final prefs = AppPreferences.instance;
      final cached = prefs.getString(_getCacheKey(homeId, entityType));
      if (cached != null) return jsonDecode(cached);
    } catch (e) {
      AppLogger.i('[SyncService] Failed to read cached $entityType data: $e');
    }
    return null;
  }

  // Clear cache
  Future<void> clearCache(String homeId, String entityType) async {
    try {
      final prefs = AppPreferences.instance;
      await prefs.remove(_getSyncKey(homeId, entityType));
      await prefs.remove(_getCacheKey(homeId, entityType));
    } catch (e) {
      AppLogger.i('[SyncService] Failed to clear $entityType cache: $e');
    }
  }

  // Get server-side updates check
  Future<Map<String, DateTime>> getServerLastUpdates(String homeId) async {
    try {
      // 1. Try to invoke the RPC
      final response = await _client.rpc(
        'get_tables_last_update',
        params: {'p_home_id': homeId},
      );
      if (response != null && response is Map) {
        return response.map((key, value) {
          final timeStr = value as String? ?? '1970-01-01';
          return MapEntry(key.toString(), DateTime.parse(timeStr));
        });
      }
    } catch (e) {
      // 2. Client-side fallback if RPC is not deployed yet
      return _fetchLastUpdatesClientSide(homeId);
    }
    return {};
  }

  Future<Map<String, DateTime>> _fetchLastUpdatesClientSide(
    String homeId,
  ) async {
    final Map<String, DateTime> updates = {};

    // Run all metadata checks in parallel to minimize latency
    final results = await Future.wait([
      _getMaxUpdatedAt('shopping_lists', 'home_id', homeId),
      _getMaxUpdatedAt(
        'shopping_items',
        'list_id',
        null,
        shoppingItemsHomeId: homeId,
      ),
      _getMaxUpdatedAt('tasks', 'home_id', homeId),
      _getMaxUpdatedAt('inventory_items', 'home_id', homeId),
      _getMaxUpdatedAt('expenses', 'home_id', homeId),
      _getMaxUpdatedAt('categories', 'home_id', homeId),
    ]);

    updates['shopping_lists'] = results[0];
    updates['shopping_items'] = results[1];
    updates['tasks'] = results[2];
    updates['inventory_items'] = results[3];
    updates['expenses'] = results[4];
    updates['categories'] = results[5];

    return updates;
  }

  Future<DateTime> _getMaxUpdatedAt(
    String table,
    String filterCol,
    String? filterVal, {
    String? shoppingItemsHomeId,
  }) async {
    try {
      if (shoppingItemsHomeId != null && table == 'shopping_items') {
        try {
          final response = await _client
              .from('shopping_items')
              .select('updated_at')
              .eq('home_id', shoppingItemsHomeId)
              .order('updated_at', ascending: false)
              .limit(1)
              .maybeSingle();

          if (response != null && response['updated_at'] != null) {
            return DateTime.parse(response['updated_at'] as String);
          }
          return DateTime.fromMillisecondsSinceEpoch(0);
        } catch (e) {
          AppLogger.i(
            '[SyncService] shopping_items.home_id max(updated_at) failed, using list_id fallback: $e',
          );
        }

        // Backward-compatible fallback for databases before shopping_items.home_id.
        final List<dynamic> lists = await _client
            .from('shopping_lists')
            .select('id')
            .eq('home_id', shoppingItemsHomeId);
        if (lists.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
        final listIds = lists
            .map((l) => (l as Map<String, dynamic>)['id'] as String)
            .toList();

        final response = await _client
            .from('shopping_items')
            .select('updated_at')
            .inFilter('list_id', listIds)
            .order('updated_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (response != null && response['updated_at'] != null) {
          return DateTime.parse(response['updated_at'] as String);
        }
      } else {
        final response = await _client
            .from(table)
            .select('updated_at')
            .eq(filterCol, filterVal!)
            .order('updated_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (response != null && response['updated_at'] != null) {
          return DateTime.parse(response['updated_at'] as String);
        }
      }
    } catch (e) {
      AppLogger.i(
        '[SyncService] Failed to fetch max updated_at for $table: $e',
      );
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(SupabaseService.client);
});
