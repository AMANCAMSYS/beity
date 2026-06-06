import 'dart:async';
import 'package:sawa/core/services/shared_prefs_provider.dart';
import 'package:sawa/core/services/local_cache_notifier.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/home_model.dart';
import '../models/home_member_model.dart';
import '../models/home_selection.dart';
import 'home_local_data_source.dart';

abstract class HomeRepository {
  Future<HomeModel> createHome({
    required String name,
    required String type,
    String? defaultCurrency,
  });

  // Local-First APIs (Requirement 1 & 2)
  Stream<List<HomeModel>> watchLocalUserHomes();
  Future<List<HomeModel>> getCachedUserHomes();
  Future<void> syncHomesWithServer();

  Stream<List<HomeMemberModel>> watchLocalHomeMembers(String homeId);
  Future<List<HomeMemberModel>> getCachedHomeMembers(String homeId);
  Future<List<HomeMemberModel>> syncMembersWithServer(String homeId);

  Future<String?> getCachedActiveHomeId(String userId);
  Stream<String?> watchActiveHomeId(String userId);

  // Legacy compatibility delegates (Local-Only now)
  Future<List<HomeModel>> getUserHomes();
  Future<List<HomeMemberModel>> getHomeMembers(String homeId);
  Future<bool> hasHomes();

  Future<void> deleteHome(String homeId);
  Future<void> removeMember({required String homeId, required String userId});
  Future<void> updateHomeCurrency({
    required String homeId,
    required String currency,
  });
}

class HomeRepositoryImpl implements HomeRepository {
  final SupabaseClient _client;
  final HomeLocalDataSource _localDataSource;

  HomeRepositoryImpl(this._client, {HomeLocalDataSource? localDataSource})
    : _localDataSource = localDataSource ?? HomeLocalDataSource(_client);

  @override
  Future<HomeModel> createHome({
    required String name,
    required String type,
    String? defaultCurrency,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('must_login_first');
      }

      final memberships = await _client
          .from('home_members')
          .select('home_id')
          .eq('user_id', user.id)
          .eq('status', 'active')
          .isFilter('deleted_at', null);

      if (memberships.length >= 20) {
        throw Exception('max_homes_reached');
      }

      final response = await _client
          .from('homes')
          .insert({
            'name': name,
            'type': type,
            'owner_id': user.id,
            'default_currency': defaultCurrency ?? 'TRY',
            'created_by': user.id,
          })
          .select()
          .single();

      final home = HomeModel.fromJson(response);

      // Save to local cache immediately
      final localDataSource = _localDataSource;
      final homes = await getCachedUserHomes();
      if (!homes.any((h) => h.id == home.id)) {
        await localDataSource.saveUserHomes(user.id, [...homes, home]);
      }

      await localDataSource.setActiveHome(home.id, home.name);

      LocalCacheNotifier.notify('global', 'homes');
      LocalCacheNotifier.notify('global', 'active_home');

      return home;
    } catch (e) {
      throw Exception('create_home_failed: ${e.toString()}');
    }
  }

  Future<String?> _getUserId() async {
    final user = _client.auth.currentUser;
    if (user != null) return user.id;

    try {
      final prefs = AppPreferences.instance;
      return prefs.getString('last_logged_in_user_id');
    } catch (_) {
      return null;
    }
  }

  // MARK: - Local-First Implementation (Requirement 1, 2, 8)

  @override
  Stream<List<HomeModel>> watchLocalUserHomes() async* {
    yield await getCachedUserHomes();
    await for (final event in LocalCacheNotifier.stream) {
      if (event.entityType == 'homes') {
        yield await getCachedUserHomes();
      }
    }
  }

  @override
  Future<List<HomeModel>> getCachedUserHomes() async {
    final userId = await _getUserId();
    if (userId == null) return [];
    final localDataSource = _localDataSource;
    return localDataSource.getUserHomes(userId);
  }

  @override
  Future<void> syncHomesWithServer() async {
    final userId = await _getUserId();
    if (userId == null) throw Exception('must_login_first');
    final localDataSource = _localDataSource;

    // 1. Fetch from Supabase
    final response = await _client
        .from('home_members')
        .select('*, homes!inner(*)')
        .eq('user_id', userId)
        .eq('status', 'active')
        .isFilter('deleted_at', null);

    final fetchedHomes = <HomeModel>[];
    for (final item in response) {
      if (item['homes'] != null) {
        fetchedHomes.add(
          HomeModel.fromJson(item['homes'] as Map<String, dynamic>),
        );
      }
    }
    final newHomes = sortAvailableHomesByNewest(fetchedHomes);

    // 2. Safety check: Do not wipe cache if server returns 0 but we have cache
    final cachedHomes = await getCachedUserHomes();
    if (newHomes.isEmpty && cachedHomes.isNotEmpty) {
      // Verify again before wiping
      try {
        final verifyResponse = await _client
            .from('home_members')
            .select('home_id')
            .eq('user_id', userId)
            .eq('status', 'active')
            .limit(1);

        if (verifyResponse.isNotEmpty) {
          // Server has data — sync failed temporarily, abort cache wipe
          return;
        }
      } catch (e) {
        // Network error — do not wipe cache
        return;
      }
      // Server confirmed 0 memberships — safe to wipe
    }

    // 3. Detect membership revocation (Requirement 3, 5, 7)
    final activeHomeId = await localDataSource.getActiveHomeIdForUser(userId);

    for (final cachedHome in cachedHomes) {
      final stillMember = newHomes.any((h) => h.id == cachedHome.id);
      if (!stillMember) {
        // Purge all data associated with this home from cache (Requirement 5)
        await localDataSource.clearAllHomeData(cachedHome.id);

        // If it was the active home, clear it until the newest valid home is selected below.
        if (activeHomeId == cachedHome.id) {
          await localDataSource.clearActiveHome(userId);
          LocalCacheNotifier.notify('global', 'active_home');
        }
      }
    }

    // 4. Save new homes to local cache
    await localDataSource.saveUserHomes(userId, newHomes);

    final selectedHome =
        findAvailableHomeById(newHomes, activeHomeId) ??
        newestAvailableHome(newHomes);
    if (selectedHome != null && selectedHome.id != activeHomeId) {
      await localDataSource.setActiveHome(selectedHome.id, selectedHome.name);
      LocalCacheNotifier.notify('global', 'active_home');
    } else if (selectedHome == null &&
        activeHomeId != null &&
        activeHomeId.isNotEmpty) {
      await localDataSource.clearActiveHome(userId);
      LocalCacheNotifier.notify('global', 'active_home');
    }

    // 5. Mark initial sync completed (Requirement 1)
    await localDataSource.setInitialSyncCompleted(userId, true);

    // 6. Notify reactive streams
    LocalCacheNotifier.notify('global', 'homes');
  }

  @override
  Stream<List<HomeMemberModel>> watchLocalHomeMembers(String homeId) async* {
    yield await getCachedHomeMembers(homeId);
    await for (final event in LocalCacheNotifier.stream) {
      if (event.homeId == homeId && event.entityType == 'home_members') {
        yield await getCachedHomeMembers(homeId);
      }
    }
  }

  @override
  Future<List<HomeMemberModel>> getCachedHomeMembers(String homeId) async {
    final localDataSource = _localDataSource;
    return localDataSource.getHomeMembers(homeId);
  }

  @override
  Future<List<HomeMemberModel>> syncMembersWithServer(String homeId) async {
    if (homeId.isEmpty) return [];

    final response = await _client
        .from('home_members')
        .select('*, users:user_id(full_name, email)')
        .eq('home_id', homeId)
        .eq('status', 'active')
        .isFilter('deleted_at', null);

    final members = response.map((item) {
      final userData = item['users'] as Map<String, dynamic>?;
      return HomeMemberModel.fromJson({
        ...item,
        'user_name': userData?['full_name'],
        'user_email': userData?['email'],
      });
    }).toList();

    // Cache home members
    final localDataSource = _localDataSource;
    await localDataSource.saveHomeMembers(homeId, members);

    // Notify reactive streams
    LocalCacheNotifier.notify(homeId, 'home_members');

    return members;
  }

  @override
  Future<String?> getCachedActiveHomeId(String userId) async {
    final localDataSource = _localDataSource;
    return localDataSource.getActiveHomeIdForUser(userId);
  }

  @override
  Stream<String?> watchActiveHomeId(String userId) async* {
    yield await getCachedActiveHomeId(userId);
    await for (final event in LocalCacheNotifier.stream) {
      if (event.entityType == 'active_home' || event.entityType == 'homes') {
        yield await getCachedActiveHomeId(userId);
      }
    }
  }

  // MARK: - Legacy compatibility delegates (Local-Only)

  @override
  Future<List<HomeModel>> getUserHomes() async {
    return getCachedUserHomes();
  }

  @override
  Future<List<HomeMemberModel>> getHomeMembers(String homeId) async {
    return getCachedHomeMembers(homeId);
  }

  @override
  Future<bool> hasHomes() async {
    final userId = await _getUserId();
    if (userId == null) return false;
    final localDataSource = _localDataSource;

    // Distinguish if initial sync has occurred (Requirement 1)
    final syncCompleted = await localDataSource.isInitialSyncCompleted(userId);
    if (!syncCompleted) {
      // If we haven't synced yet, pretend we have homes to force the app to show a Preparing/Loading spinner
      // rather than showing the OnboardingScreen immediately and flashing.
      return true;
    }

    final homes = await getCachedUserHomes();
    return homes.isNotEmpty;
  }

  @override
  Future<void> deleteHome(String homeId) async {
    final userId = await _getUserId();
    List<HomeModel> originalHomes = [];
    List<HomeModel> updatedHomes = [];
    if (userId != null) {
      originalHomes = await _localDataSource.getUserHomes(userId);
      // Optimistically remove home from user's local cached homes
      updatedHomes = originalHomes.where((h) => h.id != homeId).toList();
      await _localDataSource.saveUserHomes(userId, updatedHomes);
      LocalCacheNotifier.notify(userId, 'homes');
    }

    try {
      final user = _client.auth.currentUser;
      await _client
          .from('homes')
          .update({
            'deleted_at': DateTime.now().toIso8601String(),
            if (user != null) 'updated_by': user.id,
          })
          .eq('id', homeId);

      if (userId != null) {
        final localDataSource = _localDataSource;
        await localDataSource.clearAllHomeData(homeId);

        final activeId = await localDataSource.getActiveHomeIdForUser(userId);
        if (activeId == homeId) {
          final nextHome = newestAvailableHome(updatedHomes);
          if (nextHome == null) {
            await localDataSource.clearActiveHome(userId);
          } else {
            await localDataSource.setActiveHome(nextHome.id, nextHome.name);
          }
          LocalCacheNotifier.notify('global', 'active_home');
        }
      }
    } catch (e) {
      // Revert local cache on failure
      if (userId != null) {
        await _localDataSource.saveUserHomes(userId, originalHomes);
        LocalCacheNotifier.notify(userId, 'homes');
      }
      throw Exception('delete_home_failed: ${e.toString()}');
    }
  }

  @override
  Future<void> removeMember({
    required String homeId,
    required String userId,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('must_login_first');
      }

      await _client
          .from('home_members')
          .update({
            'deleted_at': DateTime.now().toIso8601String(),
            'status': 'inactive',
            'updated_by': user.id,
          })
          .eq('home_id', homeId)
          .eq('user_id', userId)
          .isFilter('deleted_at', null);
    } catch (e) {
      throw Exception('remove_member_failed: ${e.toString()}');
    }
  }

  @override
  Future<void> updateHomeCurrency({
    required String homeId,
    required String currency,
  }) async {
    final userId = await _getUserId();
    List<HomeModel> originalHomes = [];
    if (userId != null) {
      originalHomes = await _localDataSource.getUserHomes(userId);
      // Optimistic cache update for the updated home
      final updatedHomes = originalHomes.map((h) {
        if (h.id == homeId) {
          return HomeModel(
            id: h.id,
            name: h.name,
            type: h.type,
            ownerId: h.ownerId,
            defaultCurrency: currency,
            createdAt: h.createdAt,
            updatedAt: DateTime.now(),
            deletedAt: h.deletedAt,
            memberCount: h.memberCount,
          );
        }
        return h;
      }).toList();
      await _localDataSource.saveUserHomes(userId, updatedHomes);
      LocalCacheNotifier.notify(userId, 'homes');
    }

    try {
      final user = _client.auth.currentUser;
      await _client
          .from('homes')
          .update({
            'default_currency': currency,
            if (user != null) 'updated_by': user.id,
          })
          .eq('id', homeId);
    } catch (e) {
      // Revert cache on remote failure
      if (userId != null) {
        await _localDataSource.saveUserHomes(userId, originalHomes);
        LocalCacheNotifier.notify(userId, 'homes');
      }
      throw Exception('currency_update_failed: ${e.toString()}');
    }
  }
}
