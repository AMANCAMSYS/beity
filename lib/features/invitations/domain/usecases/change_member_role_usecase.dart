import '../../../homes/data/models/home_member_model.dart';
import '../../data/repositories/role_repository.dart';

class ChangeMemberRoleUseCase {
  final RoleRepository _repository;

  ChangeMemberRoleUseCase(this._repository);

  Future<HomeMemberModel> call({
    required String homeId,
    required String userId,
    required String newRole,
  }) async {
    if (homeId.isEmpty || userId.isEmpty) {
      throw Exception('معرف المنزل والمستخدم مطلوبان');
    }

    if (!_isValidRole(newRole)) {
      throw Exception('الدور غير صالح');
    }

    return await _repository.changeMemberRole(
      homeId: homeId,
      userId: userId,
      newRole: newRole,
    );
  }

  bool _isValidRole(String role) {
    return ['owner', 'admin', 'member', 'viewer'].contains(role);
  }
}
