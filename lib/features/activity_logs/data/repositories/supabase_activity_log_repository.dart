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
    return _client
        .from('activity_logs')
        .stream(primaryKey: ['id'])
        .eq('home_id', homeId)
        .order('created_at', ascending: false)
        .limit(limit)
        .map((response) =>
            response.map((json) => ActivityLogModel.fromJson(json)).toList());
  }

  @override
  Stream<List<ActivityLogModel>> watchListActivity({
    required String homeId,
    required String listId,
    int limit = 50,
    int offset = 0,
  }) {
    return _client
        .from('activity_logs')
        .stream(primaryKey: ['id'])
        .eq('home_id', homeId)
        .order('created_at', ascending: false)
        .limit(limit)
        .map((response) => response
            .map((json) => ActivityLogModel.fromJson(json))
            .where((log) =>
                (log.entityType == EntityType.shoppingList &&
                    log.entityId == listId) ||
                (log.metadata != null &&
                    log.metadata!['list_id'] == listId))
            .toList());
  }

  @override
  Future<List<ActivityLogModel>> getActivityLogs({
    required String homeId,
    String? actorId,
    List<ActionType>? actionTypes,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = _client
        .from('activity_logs')
        .select()
        .eq('home_id', homeId);

    if (actorId != null) {
      query = query.eq('user_id', actorId);
    }

    if (actionTypes != null && actionTypes.isNotEmpty) {
      query = query.inFilter(
          'action', actionTypes.map((a) => a.value).toList());
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => ActivityLogModel.fromJson(json))
        .toList();
  }

  @override
  Future<List<ActivityActor>> getHomeActors({required String homeId}) async {
    final response = await _client
        .from('activity_logs')
        .select('user_id, actor_name')
        .eq('home_id', homeId)
        .order('created_at', ascending: false);

    final seen = <String>{};
    final actors = <ActivityActor>[];

    for (final row in response as List) {
      final userId = row['user_id'] as String;
      if (seen.add(userId)) {
        actors.add(ActivityActor(
          userId: userId,
          displayName: row['actor_name'] as String?,
        ));
      }
    }

    return actors;
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
