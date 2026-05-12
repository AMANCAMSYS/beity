import '../../data/repositories/auth_repository.dart';
import '../../data/models/user_model.dart';

class UpdateProfileUseCase {
  final AuthRepository _repository;

  UpdateProfileUseCase(this._repository);

  Future<UserModel> call({
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    return await _repository.updateProfile(
      fullName: fullName,
      phone: phone,
      avatarUrl: avatarUrl,
    );
  }
}
