import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beity/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/role_permission_model.dart';
import '../../data/repositories/role_repository.dart';
import '../../data/repositories/supabase_role_repository.dart';
import '../../../homes/data/models/home_member_model.dart';

final roleRepositoryProvider = Provider<RoleRepository>((ref) {
  return SupabaseRoleRepository(SupabaseService.client);
});

final homeMembersProvider = FutureProvider.family<List<HomeMemberModel>, String>((ref, homeId) async {
  final repo = ref.read(roleRepositoryProvider);
  return repo.getHomeMembers(homeId: homeId);
});

final homeMembersStreamProvider = StreamProvider.autoDispose.family<List<HomeMemberModel>, String>((ref, homeId) {
  final repo = ref.read(roleRepositoryProvider);
  return repo.watchHomeMembers(homeId: homeId);
});

final rolePermissionsProvider = FutureProvider<Map<String, List<RolePermissionModel>>>((ref) async {
  final repo = ref.read(roleRepositoryProvider);
  return repo.getAllRolePermissions();
});

final userPermissionProvider = FutureProvider.family<bool, ({String homeId, String userId, String permission})>((ref, params) async {
  final repo = ref.read(roleRepositoryProvider);
  return repo.hasPermission(
    homeId: params.homeId,
    userId: params.userId,
    permission: params.permission,
  );
});

class RoleNotifier extends StateNotifier<AsyncValue<void>> {
  final RoleRepository _repo;

  RoleNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<HomeMemberModel> changeMemberRole({
    required String homeId,
    required String userId,
    required String newRole,
  }) async {
    state = const AsyncValue.loading();
    try {
      final member = await _repo.changeMemberRole(
        homeId: homeId,
        userId: userId,
        newRole: newRole,
      );
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
      await _repo.removeMember(
        homeId: homeId,
        userId: userId,
      );
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
      await _repo.transferOwnership(
        homeId: homeId,
        newOwnerId: newOwnerId,
      );
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}

final roleNotifierProvider =
    StateNotifierProvider<RoleNotifier, AsyncValue<void>>((ref) {
  final repo = ref.read(roleRepositoryProvider);
  return RoleNotifier(repo);
});
