import '../models/role_permission_model.dart';
import '../../../homes/data/models/home_member_model.dart';

abstract class RoleRepository {
  Future<HomeMemberModel> changeMemberRole({
    required String homeId,
    required String userId,
    required String newRole,
  });

  Future<void> removeMember({
    required String homeId,
    required String userId,
  });

  Future<void> transferOwnership({
    required String homeId,
    required String newOwnerId,
  });

  Future<List<HomeMemberModel>> getHomeMembers({
    required String homeId,
  });

  Future<List<RolePermissionModel>> getRolePermissions({
    required String role,
  });

  Future<Map<String, List<RolePermissionModel>>> getAllRolePermissions();

  Future<bool> hasPermission({
    required String homeId,
    required String userId,
    required String permission,
  });

  Stream<List<HomeMemberModel>> watchHomeMembers({
    required String homeId,
  });
}
