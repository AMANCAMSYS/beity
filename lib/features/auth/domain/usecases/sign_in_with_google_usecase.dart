import '../../data/repositories/auth_repository.dart';
import '../../data/models/user_model.dart';

class SignInWithGoogleUseCase {
  final AuthRepository _repository;

  SignInWithGoogleUseCase(this._repository);

  Future<UserModel> call() async {
    return _repository.signInWithGoogle();
  }
}
