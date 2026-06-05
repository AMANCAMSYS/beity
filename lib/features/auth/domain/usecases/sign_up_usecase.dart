import '../../data/repositories/auth_repository.dart';
import '../../data/models/user_model.dart';

class SignUpUseCase {
  final AuthRepository _repository;

  SignUpUseCase(this._repository);

  Future<UserModel> call({
    required String email,
    required String password,
    required String fullName,
    String? language,
  }) async {
    return _repository.signUp(
      email: email,
      password: password,
      fullName: fullName,
      language: language,
    );
  }
}
