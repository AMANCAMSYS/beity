import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sawa/core/services/supabase_service.dart';

import '../../data/models/role_permission_model.dart';
import '../../data/repositories/role_repository.dart';
import '../../data/repositories/supabase_role_repository.dart';
import '../../../homes/data/models/home_member_model.dart';
import '../../domain/entities/role.dart';

final roleRepositoryProvider = Provider<RoleRepository>((ref) {
  return SupabaseRoleRepository(SupabaseService.client);
});

final homeMembersProvider =
    FutureProvider.family<List<HomeMemberModel>, String>((ref, homeId) async {
      final repo = ref.read(roleRepositoryProvider);
      return repo.getHomeMembers(homeId: homeId);
    });

final homeMembersStreamProvider = StreamProvider.autoDispose
    .family<List<HomeMemberModel>, String>((ref, homeId) {
      final repo = ref.read(roleRepositoryProvider);
      return repo.watchHomeMembers(homeId: homeId);
    });

final rolePermissionsProvider =
    FutureProvider<Map<String, List<RolePermissionModel>>>((ref) async {
      final repo = ref.read(roleRepositoryProvider);
      return repo.getAllRolePermissions();
    });

final currentHomeRoleProvider = Provider.family<HomeRole, String>((
  ref,
  homeId,
) {
  final membersAsync = ref.watch(homeMembersStreamProvider(homeId));
  final currentUserId = SupabaseService.client.auth.currentUser?.id;
  final roleString =
      membersAsync.value
          ?.firstWhere(
            (m) => m.userId == currentUserId,
            orElse: () => HomeMemberModel(
              id: '',
              homeId: homeId,
              userId: '',
              role: 'viewer',
              status: 'active',
              joinedAt: DateTime.now(),
            ),
          )
          .role ??
      'viewer';

  return HomeRole.values.firstWhere(
    (r) => r.name == roleString,
    orElse: () => HomeRole.viewer,
  );
});

final userPermissionProvider =
    FutureProvider.family<
      bool,
      ({String homeId, String userId, String permission})
    >((ref, params) async {
      final repo = ref.read(roleRepositoryProvider);
      return repo.hasPermission(
        homeId: params.homeId,
        userId: params.userId,
        permission: params.permission,
      );
    });

class RoleNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    return null;
  }

  Future<HomeMemberModel> changeMemberRole({
    required String homeId,
    required String userId,
    required String newRole,
  }) async {
    state = const AsyncValue.loading();
    try {
      final member = await ref
          .read(roleRepositoryProvider)
          .changeMemberRole(homeId: homeId, userId: userId, newRole: newRole);
      state = const AsyncValue.data(null);
      return member;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> removeMember({
    required String homeId,
    required String userId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await ref
          .read(roleRepositoryProvider)
          .removeMember(homeId: homeId, userId: userId);
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> transferOwnership({
    required String homeId,
    required String newOwnerId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await ref
          .read(roleRepositoryProvider)
          .transferOwnership(homeId: homeId, newOwnerId: newOwnerId);
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}

final roleNotifierProvider = AsyncNotifierProvider<RoleNotifier, void>(() {
  return RoleNotifier();
});
