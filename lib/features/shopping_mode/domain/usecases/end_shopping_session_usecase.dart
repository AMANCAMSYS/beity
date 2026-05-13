import '../../data/models/shopping_mode_session_model.dart';
import '../../data/repositories/shopping_mode_repository.dart';

class EndShoppingSessionUseCase {
  final ShoppingModeRepository _repository;

  EndShoppingSessionUseCase(this._repository);

  Future<ShoppingModeSessionModel> call({
    required String sessionId,
    required int itemsPurchasedCount,
  }) async {
    return await _repository.endSession(
      sessionId: sessionId,
      itemsPurchasedCount: itemsPurchasedCount,
    );
  }
}
