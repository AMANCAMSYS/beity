import '../../data/repositories/auth_repository.dart';
import '../../data/models/user_model.dart';

class SignInUseCase {
  final AuthRepository _repository;

  SignInUseCase(this._repository);

  Future<UserModel> call({
    required String email,
    required String password,
  }) async {
    return _repository.signIn(email: email, password: password);
  }
}
