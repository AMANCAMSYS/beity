import 'dart:async';
import 'package:beity/core/services/shared_prefs_provider.dart';
import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/activity_log_model.dart';
import '../../domain/entities/activity_log.dart';
import 'activity_log_repository.dart';

class SupabaseActivityLogRepository implements ActivityLogRepository {
  final SupabaseClient _client;

  SupabaseActivityLogRepository(this._client);

  @override
  Stream<List<ActivityLogModel>> watchHomeActivity({
    required String homeId,
    int limit = 50,
    int offset = 0,
  }) {
    final controller = StreamController<List<ActivityLogModel>>();

    // Load initial data via regular query
    _loadInitialData(controller, homeId, limit, offset);

    // Also listen to realtime changes
    _client
        .from('activity_logs')
        .stream(primaryKey: ['id'])
        .eq('home_id', homeId)
        .order('created_at', ascending: false)
        .limit(limit)
        .map(
          (response) =>
              response.map((json) => ActivityLogModel.fromJson(json)).toList(),
        )
        .listen(
          (data) {
            if (!controller.isClosed) {
              controller.add(data);
            }
          },
          onError: (error) {
            // Silently handle realtime errors - initial data already loaded
          },
        );

    return controller.stream;
  }

  Future<void> _loadInitialData(
    StreamController<List<ActivityLogModel>> controller,
    String homeId,
    int limit,
    int offset,
  ) async {
    final cacheKey = 'cached_activity_logs_$homeId';
    
    // 1. Emit cached logs immediately
    try {
      final prefs = AppPreferences.instance;
      final cached = prefs.getString(cacheKey);
      if (cached != null && !controller.isClosed) {
        final List<dynamic> list = jsonDecode(cached);
        final cachedLogs = list.map((json) => ActivityLogModel.fromJson(json)).toList();
        controller.add(cachedLogs);
      }
    } catch (_) {}

    try {
      final response = await _client
          .from('activity_logs')
          .select('*, users:user_id(full_name)')
          .eq('home_id', homeId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final logs = (response as List)
          .map((json) => ActivityLogModel.fromJson(json))
          .toList();

      // Cache new logs
      try {
        final prefs = AppPreferences.instance;
        final rawJson = jsonEncode(logs.map((l) => l.toJson()).toList());
        await prefs.setString(cacheKey, rawJson);
      } catch (_) {}

      if (!controller.isClosed) {
        controller.add(logs);
      }
    } catch (e) {
      final prefs = AppPreferences.instance;
      if (!prefs.containsKey(cacheKey) && !controller.isClosed) {
        controller.addError(e);
      }
    }
  }

  @override
  Stream<List<ActivityLogModel>> watchListActivity({
    required String homeId,
    required String listId,
    int limit = 50,
    int offset = 0,
  }) {
    final controller = StreamController<List<ActivityLogModel>>();

    // Load initial data via regular query
    _loadListInitialData(controller, homeId, listId, limit, offset);

    // Also listen to realtime changes
    _client
        .from('activity_logs')
        .stream(primaryKey: ['id'])
        .eq('home_id', homeId)
        .order('created_at', ascending: false)
        .limit(limit)
        .map(
          (response) => response
              .map((json) => ActivityLogModel.fromJson(json))
              .where(
                (log) =>
                    (log.entityType == EntityType.shoppingList &&
                        log.entityId == listId) ||
                    (log.metadata != null &&
                        log.metadata!['list_id'] == listId),
              )
              .toList(),
        )
        .listen(
          (data) {
            if (!controller.isClosed) {
              controller.add(data);
            }
          },
          onError: (error) {
            // Silently handle realtime errors
          },
        );

    return controller.stream;
  }

  Future<void> _loadListInitialData(
    StreamController<List<ActivityLogModel>> controller,
    String homeId,
    String listId,
    int limit,
    int offset,
  ) async {
    final cacheKey = 'cached_activity_logs_list_${homeId}_$listId';
    
    // 1. Emit cached logs immediately
    try {
      final prefs = AppPreferences.instance;
      final cached = prefs.getString(cacheKey);
      if (cached != null && !controller.isClosed) {
        final List<dynamic> list = jsonDecode(cached);
        final cachedLogs = list.map((json) => ActivityLogModel.fromJson(json)).toList();
        controller.add(cachedLogs);
      }
    } catch (_) {}

    try {
      final response = await _client
          .from('activity_logs')
          .select('*, users:user_id(full_name)')
          .eq('home_id', homeId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final logs = (response as List)
          .map((json) => ActivityLogModel.fromJson(json))
          .where(
            (log) =>
                (log.entityType == EntityType.shoppingList &&
                    log.entityId == listId) ||
                (log.metadata != null && log.metadata!['list_id'] == listId),
          )
          .toList();

      // Cache new logs
      try {
        final prefs = AppPreferences.instance;
        final rawJson = jsonEncode(logs.map((l) => l.toJson()).toList());
        await prefs.setString(cacheKey, rawJson);
      } catch (_) {}

      if (!controller.isClosed) {
        controller.add(logs);
      }
    } catch (e) {
      final prefs = AppPreferences.instance;
      if (!prefs.containsKey(cacheKey) && !controller.isClosed) {
        controller.addError(e);
      }
    }
  }

  @override
  Future<List<ActivityLogModel>> getActivityLogs({
    required String homeId,
    String? actorId,
    List<ActionType>? actionTypes,
    int limit = 50,
    int offset = 0,
  }) async {
    final cacheKey = 'cached_activity_logs_filter_${homeId}_${actorId}_${actionTypes?.map((a) => a.value).join(',')}';
    
    try {
      var query = _client.from('activity_logs').select('*, users:user_id(full_name)').eq('home_id', homeId);

      if (actorId != null) {
        query = query.eq('user_id', actorId);
      }

      if (actionTypes != null && actionTypes.isNotEmpty) {
        query = query.inFilter(
          'action',
          actionTypes.map((a) => a.value).toList(),
        );
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final logs = (response as List)
          .map((json) => ActivityLogModel.fromJson(json))
          .toList();

      // Cache
      try {
        final prefs = AppPreferences.instance;
        final rawJson = jsonEncode(logs.map((l) => l.toJson()).toList());
        await prefs.setString(cacheKey, rawJson);
      } catch (_) {}

      return logs;
    } catch (e) {
      // Fallback to cache if offline
      try {
        final prefs = AppPreferences.instance;
        final cached = prefs.getString(cacheKey);
        if (cached != null) {
          final List<dynamic> list = jsonDecode(cached);
          return list.map((json) => ActivityLogModel.fromJson(json)).toList();
        }
      } catch (_) {}
      rethrow;
    }
  }

  @override
  Future<List<ActivityActor>> getHomeActors({required String homeId}) async {
    final cacheKey = 'cached_actors_$homeId';
    try {
      final response = await _client
          .from('home_members')
          .select('user_id, users:user_id(full_name)')
          .eq('home_id', homeId)
          .eq('status', 'active');

      final actors = <ActivityActor>[];
      final seen = <String>{};

      for (final row in response as List<dynamic>) {
        final map = row as Map<String, dynamic>;
        final userId = map['user_id'] as String;
        if (seen.add(userId)) {
          final userData = map['users'] as Map<String, dynamic>?;
          actors.add(
            ActivityActor(
              userId: userId,
              displayName: userData?['full_name'] as String?,
            ),
          );
        }
      }

      // Cache actors
      try {
        final prefs = AppPreferences.instance;
        final rawJson = jsonEncode(actors.map((a) => {'userId': a.userId, 'displayName': a.displayName}).toList());
        await prefs.setString(cacheKey, rawJson);
      } catch (_) {}

      return actors;
    } catch (e) {
      // Fallback to cache if offline
      try {
        final prefs = AppPreferences.instance;
        final cached = prefs.getString(cacheKey);
        if (cached != null) {
          final List<dynamic> list = jsonDecode(cached);
          return list.map((item) {
            final map = item as Map<String, dynamic>;
            return ActivityActor(
              userId: map['userId'] as String,
              displayName: map['displayName'] as String?,
            );
          }).toList();
        }
      } catch (_) {}
      rethrow;
    }
  }

  @override
  Future<void> logActivity({
    required String homeId,
    required ActionType action,
    required EntityType entityType,
    String? entityId,
    String? entityName,
    Map<String, dynamic>? metadata,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('activity_logs').insert({
      'home_id': homeId,
      'user_id': userId,
      'action': action.value,
      'entity_type': entityType.value,
      'entity_id': entityId,
      'entity_name': entityName,
      'metadata': metadata,
    });
  }
}
