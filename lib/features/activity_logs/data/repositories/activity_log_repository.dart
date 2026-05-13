import '../models/activity_log_model.dart';
import '../../domain/entities/activity_log.dart';

abstract class ActivityLogRepository {
  Stream<List<ActivityLogModel>> watchHomeActivity({
    required String homeId,
    int limit = 50,
    int offset = 0,
  });

  Stream<List<ActivityLogModel>> watchListActivity({
    required String homeId,
    required String listId,
    int limit = 50,
    int offset = 0,
  });

  Future<List<ActivityLogModel>> getActivityLogs({
    required String homeId,
    String? actorId,
    List<ActionType>? actionTypes,
    int limit = 50,
    int offset = 0,
  });

  Future<List<ActivityActor>> getHomeActors({required String homeId});
}
