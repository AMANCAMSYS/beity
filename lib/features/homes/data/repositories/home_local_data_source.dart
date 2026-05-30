import 'dart:convert';
import 'package:beity/core/services/supabase_service.dart';
import 'package:beity/core/services/shared_prefs_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/home_model.dart';
import '../models/home_member_model.dart';

class HomeLocalDataSource {
  final SupabaseClient? _client;

  HomeLocalDataSource([this._client]);

  String _getUserId() {
    final client = _client ?? SupabaseService.client;
    final user = client.auth.currentUser;
    return user?.id ?? 'anonymous';
  }

  // User-isolated cache keys (Requirement 5)
  String _homesCacheKey(String userId) => 'homes_cache_user:$userId';
  String _activeHomeKey(String userId) => 'active_home_user:$userId';
  String _activeHomeNameKey(String userId) => 'active_home_name_user:$userId';
  String _membersCacheKey(String homeId) => 'home_members_cache_home:$homeId';
  String _initialSyncCompletedKey(String userId) => 'initial_sync_completed_user:$userId';
  String _homeInitialSyncCompletedKey(String homeId) => 'initial_sync_completed_home:$homeId';

  // Save/Load user homes list (Requirement 5)
  Future<void> saveUserHomes(String userId, List<HomeModel> homes) async {
    final prefs = AppPreferences.instance;
    final rawJson = jsonEncode(homes.map((h) => h.toJson()).toList());
    await prefs.setString(_homesCacheKey(userId), rawJson);
  }

  Future<List<HomeModel>> getUserHomes(String userId) async {
    try {
      final prefs = AppPreferences.instance;
      final cached = prefs.getString(_homesCacheKey(userId));
      if (cached == null) return [];
      final List<dynamic> list = jsonDecode(cached);
      return list.map((item) => HomeModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // Save/Load home members (Requirement 5)
  Future<void> saveHomeMembers(String homeId, List<HomeMemberModel> members) async {
    final prefs = AppPreferences.instance;
    final rawJson = jsonEncode(members.map((m) => m.toJson()).toList());
    await prefs.setString(_membersCacheKey(homeId), rawJson);
  }

  Future<List<HomeMemberModel>> getHomeMembers(String homeId) async {
    try {
      final prefs = AppPreferences.instance;
      final cached = prefs.getString(_membersCacheKey(homeId));
      if (cached == null) return [];
      final List<dynamic> list = jsonDecode(cached);
      return list.map((item) => HomeMemberModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clearHomeMembers(String homeId) async {
    final prefs = AppPreferences.instance;
    await prefs.remove(_membersCacheKey(homeId));
  }

  Future<void> clearAllHomeData(String homeId) async {
    final prefs = AppPreferences.instance;
    final keys = prefs.getKeys().toList();
    for (final key in keys) {
      if (key.contains(homeId)) {
        await prefs.remove(key);
      }
    }
  }

  // Save/Load active home ID & name (Requirement 5)
  Future<void> setActiveHome(String homeId, String homeName) async {
    final prefs = AppPreferences.instance;
    final userId = _getUserId();
    await prefs.setString(_activeHomeKey(userId), homeId);
    await prefs.setString(_activeHomeNameKey(userId), homeName);
  }

  Future<String?> getActiveHomeId() async {
    final prefs = AppPreferences.instance;
    final userId = _getUserId();
    return prefs.getString(_activeHomeKey(userId));
  }

  Future<String?> getActiveHomeIdForUser(String userId) async {
    final prefs = AppPreferences.instance;
    return prefs.getString(_activeHomeKey(userId));
  }

  Future<String?> getActiveHomeName() async {
    final prefs = AppPreferences.instance;
    final userId = _getUserId();
    return prefs.getString(_activeHomeNameKey(userId));
  }

  Future<void> clearActiveHome(String userId) async {
    final prefs = AppPreferences.instance;
    await prefs.remove(_activeHomeKey(userId));
    await prefs.remove(_activeHomeNameKey(userId));
  }

  // Initial Sync completed status tracker (Requirement 1 & 5)
  Future<void> setInitialSyncCompleted(String userId, bool completed) async {
    final prefs = AppPreferences.instance;
    await prefs.setBool(_initialSyncCompletedKey(userId), completed);
  }

  Future<bool> isInitialSyncCompleted(String userId) async {
    try {
      final prefs = AppPreferences.instance;
      return prefs.getBool(_initialSyncCompletedKey(userId)) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> setHomeInitialSyncCompleted(String homeId, bool completed) async {
    final prefs = AppPreferences.instance;
    await prefs.setBool(_homeInitialSyncCompletedKey(homeId), completed);
  }

  Future<bool> isHomeInitialSyncCompleted(String homeId) async {
    try {
      final prefs = AppPreferences.instance;
      return prefs.getBool(_homeInitialSyncCompletedKey(homeId)) ?? false;
    } catch (_) {
      return false;
    }
  }

  // Comprehensive logout cleanup (Requirement 4 & 6)
  Future<void> clearAllUserData() async {
    final userId = _getUserId();
    await clearAllUserDataForUser(userId);
  }

  Future<void> clearAllUserDataForUser(String userId) async {
    final prefs = AppPreferences.instance;
    final keys = prefs.getKeys().toList();

    // 1. Resolve user's cached homes first to purge all their sub-feature caches
    List<String> homeIds = [];
    try {
      final homesKey = _homesCacheKey(userId);
      final cachedHomes = prefs.getString(homesKey);
      if (cachedHomes != null) {
        final List<dynamic> decoded = jsonDecode(cachedHomes);
        homeIds = decoded.map((h) => (h as Map<String, dynamic>)['id'] as String).toList();
      }
    } catch (_) {}

    // 2. Loop over and delete all user-owned and home-owned keys
    for (final key in keys) {
      // Clear user-specific structural keys
      if (key == _homesCacheKey(userId) ||
          key == _activeHomeKey(userId) ||
          key == _activeHomeNameKey(userId) ||
          key == _initialSyncCompletedKey(userId)) {
        await prefs.remove(key);
        continue;
      }

      // Clear legacy active home keys or keys starting with userId_
      if (key.startsWith('${userId}_') || key.startsWith('sync_queue_$userId')) {
        await prefs.remove(key);
        continue;
      }

      // Clear all caching keys belonging to any home this user had membership in
      // Purges shopping, tasks, expenses, inventory, categories, lastSyncAt timestamps, outbox
      for (final homeId in homeIds) {
        if (key.contains(homeId)) {
          await prefs.remove(key);
          break;
        }
      }
    }

    // 3. Clear home member lists and flags
    for (final homeId in homeIds) {
      await prefs.remove(_membersCacheKey(homeId));
      await prefs.remove(_homeInitialSyncCompletedKey(homeId));
    }
  }
}
