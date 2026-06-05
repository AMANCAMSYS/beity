import 'dart:async';

import 'package:sawa/core/local_database/daos/activity_logs_dao.dart';
import 'package:sawa/core/local_database/daos/homes_dao.dart';
import 'package:sawa/core/local_database/local_database_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/activity_log_model.dart';
import '../../domain/entities/activity_log.dart';
import 'activity_log_repository.dart';

class SupabaseActivityLogRepository implements ActivityLogRepository {
  final SupabaseClient _client;
  final ActivityLogsDao _activityLogsDao;
  final HomesDao _homesDao;

  SupabaseActivityLogRepository(
    this._client, {
    ActivityLogsDao? activityLogsDao,
    HomesDao? homesDao,
  }) : _activityLogsDao =
           activityLogsDao ?? ActivityLogsDao(LocalDatabaseService.instance),
       _homesDao = homesDao ?? HomesDao(LocalDatabaseService.instance);

  @override
  Stream<List<ActivityLogModel>> watchHomeActivity({
    required String homeId,
    int limit = 50,
    int offset = 0,
  }) {
    final controller = StreamController<List<ActivityLogModel>>();
    StreamSubscription<List<ActivityLogModel>>? localSubscription;
    StreamSubscription<List<Map<String, dynamic>>>? remoteSubscription;

    controller.onListen = () {
      localSubscription = _activityLogsDao
          .watchActivityLogs(homeId: homeId, limit: limit, offset: offset)
          .listen(
            controller.add,
            onError: (error, stackTrace) {
              if (!controller.isClosed) {
                controller.addError(error, stackTrace);
              }
            },
          );

      unawaited(_refreshActivityLogs(homeId: homeId, limit: limit, offset: 0));

      remoteSubscription = _client
          .from('activity_logs')
          .stream(primaryKey: ['id'])
          .eq('home_id', homeId)
          .order('created_at', ascending: false)
          .limit(limit)
          .listen(
            (response) {
              unawaited(_saveRemoteRows(response));
            },
            onError: (_) {
              // Offline or realtime errors should not break the local stream.
            },
          );
    };

    controller.onCancel = () async {
      await localSubscription?.cancel();
      await remoteSubscription?.cancel();
      await controller.close();
    };

    return controller.stream;
  }

  @override
  Stream<List<ActivityLogModel>> watchListActivity({
    required String homeId,
    required String listId,
    int limit = 50,
    int offset = 0,
  }) {
    final controller = StreamController<List<ActivityLogModel>>();
    StreamSubscription<List<ActivityLogModel>>? localSubscription;
    StreamSubscription<List<Map<String, dynamic>>>? remoteSubscription;

    controller.onListen = () {
      localSubscription = _activityLogsDao
          .watchListActivityLogs(
            homeId: homeId,
            listId: listId,
            limit: limit,
            offset: offset,
          )
          .listen(
            controller.add,
            onError: (error, stackTrace) {
              if (!controller.isClosed) {
                controller.addError(error, stackTrace);
              }
            },
          );

      unawaited(_refreshActivityLogs(homeId: homeId, limit: limit, offset: 0));

      remoteSubscription = _client
          .from('activity_logs')
          .stream(primaryKey: ['id'])
          .eq('home_id', homeId)
          .order('created_at', ascending: false)
          .limit(limit)
          .listen(
            (response) {
              unawaited(_saveRemoteRows(response));
            },
            onError: (_) {
              // Offline or realtime errors should not break the local stream.
            },
          );
    };

    controller.onCancel = () async {
      await localSubscription?.cancel();
      await remoteSubscription?.cancel();
      await controller.close();
    };

    return controller.stream;
  }

  @override
  Future<List<ActivityLogModel>> getActivityLogs({
    required String homeId,
    String? actorId,
    List<ActionType>? actionTypes,
    int limit = 50,
    int offset = 0,
  }) async {
    final localLogs = await _activityLogsDao.getActivityLogs(
      homeId: homeId,
      actorId: actorId,
      actionTypes: actionTypes,
      limit: limit,
      offset: offset,
    );
    final refresh = _refreshActivityLogs(
      homeId: homeId,
      actorId: actorId,
      actionTypes: actionTypes,
      limit: limit,
      offset: offset,
    );

    if (localLogs.isNotEmpty || offset > 0) {
      unawaited(refresh);
      return localLogs;
    }

    try {
      await refresh;
      return _activityLogsDao.getActivityLogs(
        homeId: homeId,
        actorId: actorId,
        actionTypes: actionTypes,
        limit: limit,
        offset: offset,
      );
    } catch (_) {
      return localLogs;
    }
  }

  @override
  Future<ActivityLogModel?> getActivityLogById(String id) async {
    final localLog = await _activityLogsDao.getActivityLogById(id);
    if (localLog != null) return localLog;

    try {
      final response = await _client
          .from('activity_logs')
          .select('*, users:user_id(full_name)')
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      final log = ActivityLogModel.fromJson(response);
      await _activityLogsDao.upsertActivityLogs([log]);
      return log;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<ActivityActor>> getHomeActors({required String homeId}) async {
    final localMembers = await _homesDao.getHomeMembers(homeId);
    if (localMembers.isNotEmpty) {
      return localMembers
          .map(
            (member) => ActivityActor(
              userId: member.userId,
              displayName: member.userName,
            ),
          )
          .toList();
    }

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

      return actors;
    } catch (_) {
      return const [];
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

    final response = await _client
        .from('activity_logs')
        .insert({
          'home_id': homeId,
          'user_id': userId,
          'action': action.value,
          'entity_type': entityType.value,
          'entity_id': entityId,
          'entity_name': entityName,
          'metadata': metadata,
        })
        .select('*, users:user_id(full_name)')
        .maybeSingle();

    if (response != null) {
      await _activityLogsDao.upsertActivityLogs([
        ActivityLogModel.fromJson(response),
      ]);
    }
  }

  Future<void> _refreshActivityLogs({
    required String homeId,
    String? actorId,
    List<ActionType>? actionTypes,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = _client
        .from('activity_logs')
        .select('*, users:user_id(full_name)')
        .eq('home_id', homeId);

    if (actorId != null && actorId.isNotEmpty) {
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
        .map((json) => ActivityLogModel.fromJson(json as Map<String, dynamic>))
        .toList();
    await _activityLogsDao.upsertActivityLogs(logs);
  }

  Future<void> _saveRemoteRows(List<Map<String, dynamic>> rows) async {
    final logs = rows.map(ActivityLogModel.fromJson).toList();
    await _activityLogsDao.upsertActivityLogs(logs);
  }
}
