import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sawa/core/constants/app_constants.dart';
import 'package:sawa/core/services/supabase_service.dart';
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

      return repository.watchHomeActivity(homeId: homeId, limit: 50).map((
        logs,
      ) {
        return membersAsync.when(
          data: (members) {
            final memberMap = {for (final m in members) m.userId: m.userName};
            return logs.map((log) {
              if (log.actorName == null ||
                  log.actorName == AppConstants.defaultUserNameKey ||
                  log.actorName!.isEmpty) {
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
              if (log.actorName == null ||
                  log.actorName == AppConstants.defaultUserNameKey ||
                  log.actorName!.isEmpty) {
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

final listActivityProvider = StreamProvider.autoDispose
    .family<List<ActivityLogModel>, ListActivityParams>((ref, params) {
      final repository = ref.watch(activityLogRepositoryProvider);
      final homeId = params.homeId;
      final listId = params.listId;

      final membersAsync = ref.watch(homeMembersProvider(homeId));

      return repository
          .watchListActivity(homeId: homeId, listId: listId, limit: 100)
          .map((logs) {
            return membersAsync.when(
              data: (members) {
                final memberMap = {
                  for (final m in members) m.userId: m.userName,
                };
                return logs.map((log) {
                  if (log.actorName == null ||
                      log.actorName == AppConstants.defaultUserNameKey ||
                      log.actorName!.isEmpty) {
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

typedef FilteredActivityParams = ({String homeId, ActivityFilter filter});

final filteredActivityProvider = FutureProvider.autoDispose
    .family<List<ActivityLogModel>, FilteredActivityParams>((
      ref,
      params,
    ) async {
      final repository = ref.watch(activityLogRepositoryProvider);
      final logs = await repository.getActivityLogs(
        homeId: params.homeId,
        actorId: params.filter.actorId,
        actionTypes: params.filter.actionTypes,
      );

      // Try to enrich names using homeMembersProvider
      final membersAsync = ref.watch(homeMembersProvider(params.homeId));
      return membersAsync.when(
        data: (members) {
          final memberMap = {for (final m in members) m.userId: m.userName};
          return logs.map((log) {
            if (log.actorName == null ||
                log.actorName == 'مستخدم' ||
                log.actorName!.isEmpty) {
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

final activityLogByIdProvider = FutureProvider.autoDispose
    .family<ActivityLogModel?, String>((ref, id) async {
      final repository = ref.watch(activityLogRepositoryProvider);
      return repository.getActivityLogById(id);
    });

final activityActorsProvider =
    FutureProvider.family<List<ActivityActor>, String>((ref, homeId) {
      final repository = ref.watch(activityLogRepositoryProvider);
      return repository.getHomeActors(homeId: homeId);
    });

final activityFilterProvider =
    NotifierProvider<ActivityFilterNotifier, ActivityFilter>(() {
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ActivityFilter &&
        other.actorId == actorId &&
        _listEquals(other.actionTypes, actionTypes);
  }

  @override
  int get hashCode => actorId.hashCode ^ _listHashCode(actionTypes);

  bool _listEquals(List<ActionType>? a, List<ActionType>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  int _listHashCode(List<ActionType>? list) {
    if (list == null) return 0;
    return list.fold(0, (hash, item) => hash ^ item.hashCode);
  }
}

class ActivityFilterNotifier extends Notifier<ActivityFilter> {
  @override
  ActivityFilter build() {
    return const ActivityFilter();
  }

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
