import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beity/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/activity_log_model.dart';
import '../../data/repositories/activity_log_repository.dart';
import '../../data/repositories/supabase_activity_log_repository.dart';
import '../../domain/entities/activity_log.dart';

import '../../../invitations/presentation/providers/roles_provider.dart';

final activityLogRepositoryProvider = Provider<ActivityLogRepository>((ref) {
  final client = SupabaseService.client;
  return SupabaseActivityLogRepository(client);
});

final homeActivityProvider = StreamProvider.autoDispose
    .family<List<ActivityLogModel>, String>((ref, homeId) {
      final repository = ref.watch(activityLogRepositoryProvider);
      final membersAsync = ref.watch(homeMembersProvider(homeId));

      return repository.watchHomeActivity(homeId: homeId, limit: 50).map((logs) {
        return membersAsync.when(
          data: (members) {
            final memberMap = {for (final m in members) m.userId: m.userName};
            return logs.map((log) {
              if (log.actorName == null || log.actorName == 'مستخدم' || log.actorName!.isEmpty) {
                final cachedName = memberMap[log.userId];
                if (cachedName != null && cachedName.isNotEmpty) {
                  return log.copyWithModel(actorName: cachedName);
                }
              }
              return log;
            }).toList();
          },
          loading: () => logs,
          error: (error, stack) => logs,
        );
      });
    });

final recentHomeActivityProvider = StreamProvider.autoDispose
    .family<List<ActivityLogModel>, String>((ref, homeId) {
      final repository = ref.watch(activityLogRepositoryProvider);
      final membersAsync = ref.watch(homeMembersProvider(homeId));

      return repository.watchHomeActivity(homeId: homeId, limit: 5).map((logs) {
        return membersAsync.when(
          data: (members) {
            final memberMap = {for (final m in members) m.userId: m.userName};
            return logs.map((log) {
              if (log.actorName == null || log.actorName == 'مستخدم' || log.actorName!.isEmpty) {
                final cachedName = memberMap[log.userId];
                if (cachedName != null && cachedName.isNotEmpty) {
                  return log.copyWithModel(actorName: cachedName);
                }
              }
              return log;
            }).toList();
          },
          loading: () => logs,
          error: (error, stack) => logs,
        );
      });
    });

typedef ListActivityParams = ({String homeId, String listId});

final listActivityProvider = FutureProvider.autoDispose
    .family<List<ActivityLogModel>, ListActivityParams>((ref, params) async {
      final repository = ref.watch(activityLogRepositoryProvider);
      final homeId = params.homeId;
      final listId = params.listId;
      final logs = await repository.getActivityLogs(homeId: homeId, limit: 100);
      final filteredLogs = logs
          .where(
            (log) =>
                (log.entityType == EntityType.shoppingList &&
                    log.entityId == listId) ||
                (log.metadata != null && log.metadata!['list_id'] == listId),
          )
          .toList();

      // Try to enrich names using homeMembersProvider
      final membersAsync = ref.watch(homeMembersProvider(homeId));
      return membersAsync.when(
        data: (members) {
          final memberMap = {for (final m in members) m.userId: m.userName};
          return filteredLogs.map((log) {
            if (log.actorName == null || log.actorName == 'مستخدم' || log.actorName!.isEmpty) {
              final cachedName = memberMap[log.userId];
              if (cachedName != null && cachedName.isNotEmpty) {
                return log.copyWithModel(actorName: cachedName);
              }
            }
            return log;
          }).toList();
        },
        loading: () => filteredLogs,
        error: (error, stack) => filteredLogs,
      );
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
      actionTypes: clearActions ? null : (actionTypes ?? this.actionTypes),
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
    state = state.copyWith(actionTypes: types, clearActions: types == null);
  }

  void clear() {
    state = const ActivityFilter();
  }
}
