import '../../data/repositories/role_repository.dart';

class RemoveMemberUseCase {
  final RoleRepository _repository;

  RemoveMemberUseCase(this._repository);

  Future<void> call({required String homeId, required String userId}) async {
    if (homeId.isEmpty || userId.isEmpty) {
      throw Exception('home_user_required');
    }

    await _repository.removeMember(homeId: homeId, userId: userId);
  }
}
