import '../models/shopping_mode_session_model.dart';

abstract class ShoppingModeRepository {
  Future<ShoppingModeSessionModel?> getActiveSession({
    required String userId,
    required String listId,
  });

  Future<ShoppingModeSessionModel> startSession({
    required String listId,
    required String userId,
    required String homeId,
    required int itemsTotalCount,
  });

  Future<ShoppingModeSessionModel> endSession({
    required String sessionId,
    required int itemsPurchasedCount,
  });
}
