import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared_prefs_provider.dart';
import 'supabase_service.dart';


class SyncService {
  final SupabaseClient _client;
  
  SyncService(this._client);
  
  // Storage keys generator
  String _getSyncKey(String homeId, String entityType) => 'sync_ts_${homeId}_$entityType';
  String _getCacheKey(String homeId, String entityType) => 'sync_cache_${homeId}_$entityType';
  
  // Get last local sync time
  DateTime getLocalSyncTime(String homeId, String entityType) {
    try {
      final prefs = AppPreferences.instance;
      final tsStr = prefs.getString(_getSyncKey(homeId, entityType));
      if (tsStr == null) return DateTime.fromMillisecondsSinceEpoch(0);
      return DateTime.parse(tsStr);
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }
  
  // Update local sync time
  Future<void> updateLocalSyncTime(String homeId, String entityType, DateTime time) async {
    try {
      final prefs = AppPreferences.instance;
      await prefs.setString(_getSyncKey(homeId, entityType), time.toIso8601String());
    } catch (_) {}
  }
  
  // Save local data cache helper
  Future<void> cacheData(String homeId, String entityType, dynamic data) async {
    try {
      final prefs = AppPreferences.instance;
      await prefs.setString(_getCacheKey(homeId, entityType), jsonEncode(data));
    } catch (_) {}
  }
  
  // Retrieve local data cache helper
  dynamic getCachedData(String homeId, String entityType) {
    try {
      final prefs = AppPreferences.instance;
      final cached = prefs.getString(_getCacheKey(homeId, entityType));
      if (cached != null) return jsonDecode(cached);
    } catch (_) {}
    return null;
  }
  
  // Clear cache
  Future<void> clearCache(String homeId, String entityType) async {
    try {
      final prefs = AppPreferences.instance;
      await prefs.remove(_getSyncKey(homeId, entityType));
      await prefs.remove(_getCacheKey(homeId, entityType));
    } catch (_) {}
  }

  // Get server-side updates check
  Future<Map<String, DateTime>> getServerLastUpdates(String homeId) async {
    try {
      // 1. Try to invoke the RPC
      final response = await _client.rpc('get_tables_last_update', params: {'p_home_id': homeId});
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
  
  Future<Map<String, DateTime>> _fetchLastUpdatesClientSide(String homeId) async {
    final Map<String, DateTime> updates = {};
    
    // Run all metadata checks in parallel to minimize latency
    final results = await Future.wait([
      _getMaxUpdatedAt('shopping_lists', 'home_id', homeId),
      _getMaxUpdatedAt('shopping_items', 'list_id', null, shoppingItemsHomeId: homeId),
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
  
  Future<DateTime> _getMaxUpdatedAt(String table, String filterCol, String? filterVal, {String? shoppingItemsHomeId}) async {
    try {
      if (shoppingItemsHomeId != null && table == 'shopping_items') {
        // Shopping items need to join shopping_lists
        final List<dynamic> lists = await _client
            .from('shopping_lists')
            .select('id')
            .eq('home_id', shoppingItemsHomeId)
            .isFilter('deleted_at', null);
        if (lists.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
        final listIds = lists.map((l) => (l as Map<String, dynamic>)['id'] as String).toList();
        
        final response = await _client
            .from('shopping_items')
            .select('updated_at')
            .inFilter('list_id', listIds)
            .isFilter('deleted_at', null)
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
            .isFilter('deleted_at', null)
            .order('updated_at', ascending: false)
            .limit(1)
            .maybeSingle();
            
        if (response != null && response['updated_at'] != null) {
          return DateTime.parse(response['updated_at'] as String);
        }
      }
    } catch (_) {}
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(SupabaseService.client);
});
