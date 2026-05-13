import '../../data/models/shopping_mode_session_model.dart';
import '../../data/repositories/shopping_mode_repository.dart';

class GetActiveSessionUseCase {
  final ShoppingModeRepository _repository;

  GetActiveSessionUseCase(this._repository);

  Future<ShoppingModeSessionModel?> call({
    required String userId,
    required String listId,
  }) async {
    return await _repository.getActiveSession(
      userId: userId,
      listId: listId,
    );
  }
}
