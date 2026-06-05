import '../../data/repositories/role_repository.dart';

class TransferOwnershipUseCase {
  final RoleRepository _repository;

  TransferOwnershipUseCase(this._repository);

  Future<void> call({
    required String homeId,
    required String newOwnerId,
  }) async {
    if (homeId.isEmpty || newOwnerId.isEmpty) {
      throw Exception('home_owner_required');
    }

    await _repository.transferOwnership(
      homeId: homeId,
      newOwnerId: newOwnerId,
    );
  }
}
