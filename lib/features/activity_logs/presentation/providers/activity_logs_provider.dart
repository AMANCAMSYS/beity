import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/activity_log_model.dart';
import '../../data/repositories/activity_log_repository.dart';
import '../../data/repositories/supabase_activity_log_repository.dart';
import '../../domain/entities/activity_log.dart';

final activityLogRepositoryProvider = Provider<ActivityLogRepository>((ref) {
  final client = Supabase.instance.client;
  return SupabaseActivityLogRepository(client);
});

final homeActivityProvider =
    FutureProvider.autoDispose.family<List<ActivityLogModel>, String>((ref, homeId) async {
  final repository = ref.watch(activityLogRepositoryProvider);
  return repository.getActivityLogs(homeId: homeId, limit: 50);
});

final listActivityProvider =
    FutureProvider.autoDispose.family<List<ActivityLogModel>, List<String>>((ref, params) async {
  final repository = ref.watch(activityLogRepositoryProvider);
  final homeId = params[0];
  final listId = params[1];
  final logs = await repository.getActivityLogs(homeId: homeId, limit: 100);
  return logs.where((log) =>
      (log.entityType == EntityType.shoppingList && log.entityId == listId) ||
      (log.metadata != null && log.metadata!['list_id'] == listId)
  ).toList();
});

final activityActorsProvider =
    FutureProvider.family<List<ActivityActor>, String>((ref, homeId) {
  final repository = ref.watch(activityLogRepositoryProvider);
  return repository.getHomeActors(homeId: homeId);
});

final activityFilterProvider =
    StateNotifierProvider<ActivityFilterNotifier, ActivityFilter>((ref) {
  return ActivityFilterNotifier();
});

class ActivityFilter {
  final String? actorId;
  final List<ActionType>? actionTypes;

  const ActivityFilter({this.actorId, this.actionTypes});

  ActivityFilter copyWith({
    String? actorId,
    List<ActionType>? actionTypes,
    bool clearActor = false,
    bool clearActions = false,
  }) {
    return ActivityFilter(
      actorId: clearActor ? null : (actorId ?? this.actorId),
      actionTypes:
          clearActions ? null : (actionTypes ?? this.actionTypes),
    );
  }

  bool get isActive => actorId != null || actionTypes != null;
}

class ActivityFilterNotifier extends StateNotifier<ActivityFilter> {
  ActivityFilterNotifier() : super(const ActivityFilter());

  void setActor(String? actorId) {
    state = state.copyWith(actorId: actorId, clearActor: actorId == null);
  }

  void setActionTypes(List<ActionType>? types) {
    state =
        state.copyWith(actionTypes: types, clearActions: types == null);
  }

  void clear() {
    state = const ActivityFilter();
  }
}
