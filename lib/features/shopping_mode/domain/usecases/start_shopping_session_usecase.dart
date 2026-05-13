import '../../data/models/shopping_mode_session_model.dart';
import '../../data/repositories/shopping_mode_repository.dart';

class StartShoppingSessionUseCase {
  final ShoppingModeRepository _repository;

  StartShoppingSessionUseCase(this._repository);

  Future<ShoppingModeSessionModel> call({
    required String listId,
    required String userId,
    required String homeId,
    required int itemsTotalCount,
  }) async {
    // Check for existing active session
    final existing = await _repository.getActiveSession(
      userId: userId,
      listId: listId,
    );

    if (existing != null) {
      return existing;
    }

    return await _repository.startSession(
      listId: listId,
      userId: userId,
      homeId: homeId,
      itemsTotalCount: itemsTotalCount,
    );
  }
}
