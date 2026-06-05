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
      throw Exception('home_user_required');
    }

    if (!_isValidRole(newRole)) {
      throw Exception('invalid_role');
    }

    return _repository.changeMemberRole(
      homeId: homeId,
      userId: userId,
      newRole: newRole,
    );
  }

  bool _isValidRole(String role) {
    return ['owner', 'admin', 'member', 'viewer'].contains(role);
  }
}
