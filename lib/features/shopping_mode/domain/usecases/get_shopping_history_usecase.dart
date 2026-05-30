import '../../data/models/shopping_mode_session_model.dart';
import '../../data/repositories/shopping_mode_repository.dart';

class GetShoppingHistoryUseCase {
  final ShoppingModeRepository _repository;

  GetShoppingHistoryUseCase(this._repository);

  Future<List<ShoppingModeSessionModel>> call({
    required String userId,
    int limit = 20,
  }) async {
    return _repository.getShoppingHistory(
      userId: userId,
      limit: limit,
    );
  }
}
