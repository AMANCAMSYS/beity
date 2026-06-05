import 'package:sawa/core/local_database/daos/homes_dao.dart';
import 'package:sawa/core/local_database/local_database_service.dart';
import 'package:sawa/core/services/shared_prefs_provider.dart';
import 'package:sawa/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/home_member_model.dart';
import '../models/home_model.dart';

class HomeLocalDataSource {
  final SupabaseClient? _client;
  final HomesDao _dao;

  HomeLocalDataSource([this._client, HomesDao? dao])
    : _dao = dao ?? HomesDao(LocalDatabaseService.instance);

  String _getUserId() {
    final client = _client ?? SupabaseService.client;
    final user = client.auth.currentUser;
    return user?.id ?? 'anonymous';
  }

  Future<void> saveUserHomes(String userId, List<HomeModel> homes) {
    return _dao.saveUserHomes(userId, homes);
  }

  Future<List<HomeModel>> getUserHomes(String userId) {
    return _dao.getUserHomes(userId);
  }

  Stream<List<HomeModel>> watchUserHomes(String userId) {
    return _dao.watchUserHomes(userId);
  }

  Future<void> saveHomeMembers(String homeId, List<HomeMemberModel> members) {
    return _dao.saveHomeMembers(homeId, members);
  }

  Future<List<HomeMemberModel>> getHomeMembers(String homeId) {
    return _dao.getHomeMembers(homeId);
  }

  Stream<List<HomeMemberModel>> watchHomeMembers(String homeId) {
    return _dao.watchHomeMembers(homeId);
  }

  Future<void> clearHomeMembers(String homeId) {
    return _dao.clearHomeMembers(homeId);
  }

  Future<void> clearAllHomeData(String homeId) {
    return _dao.clearAllHomeData(homeId);
  }

  Future<void> setActiveHome(String homeId, String homeName) {
    return _dao.setActiveHome(_getUserId(), homeId, homeName);
  }

  Future<String?> getActiveHomeId() {
    return _dao.getActiveHomeIdForUser(_getUserId());
  }

  Future<String?> getActiveHomeIdForUser(String userId) {
    return _dao.getActiveHomeIdForUser(userId);
  }

  Future<String?> getActiveHomeName() {
    return _dao.getActiveHomeNameForUser(_getUserId());
  }

  Future<void> clearActiveHome(String userId) {
    return _dao.clearActiveHome(userId);
  }

  Future<void> setInitialSyncCompleted(String userId, bool completed) {
    return _dao.setInitialSyncCompleted(userId, completed);
  }

  Future<bool> isInitialSyncCompleted(String userId) {
    return _dao.isInitialSyncCompleted(userId);
  }

  Future<void> setHomeInitialSyncCompleted(String homeId, bool completed) {
    return _dao.setHomeInitialSyncCompleted(homeId, completed);
  }

  Future<bool> isHomeInitialSyncCompleted(String homeId) {
    return _dao.isHomeInitialSyncCompleted(homeId);
  }

  Future<void> clearAllUserData() {
    return clearAllUserDataForUser(_getUserId());
  }

  Future<void> clearAllUserDataForUser(String userId) async {
    // 1. Clear Drift data
    await _dao.clearAllUserDataForUser(userId);

    // 2. Clear legacy SharedPreferences keys owned by this user
    final prefs = AppPreferences.instance;
    final keys = prefs.getKeys().toList();
    for (final key in keys) {
      if (key.startsWith('${userId}_') ||
          key.startsWith('homes_cache_user:$userId') ||
          key.startsWith('active_home_user:$userId') ||
          key.startsWith('active_home_name_user:$userId') ||
          key.startsWith('initial_sync_completed_user:$userId') ||
          key.startsWith('sync_queue_$userId') ||
          key.endsWith('_cached_profile') && key.startsWith(userId)) {
        await prefs.remove(key);
      }
    }
  }
}
