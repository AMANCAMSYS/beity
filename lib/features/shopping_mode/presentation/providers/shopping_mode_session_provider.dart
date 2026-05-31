import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beity/core/services/supabase_service.dart';
import '../../data/models/shopping_mode_session_model.dart';
import '../../data/repositories/shopping_mode_repository.dart';
import '../../data/repositories/supabase_shopping_mode_repository.dart';
import '../../domain/usecases/start_shopping_session_usecase.dart';
import '../../domain/usecases/end_shopping_session_usecase.dart';
import '../../domain/usecases/get_active_session_usecase.dart';

final shoppingModeRepositoryProvider = Provider<ShoppingModeRepository>((ref) {
  final client = SupabaseService.client;
  return SupabaseShoppingModeRepository(client);
});

final startShoppingSessionUseCaseProvider =
    Provider<StartShoppingSessionUseCase>((ref) {
  final repository = ref.watch(shoppingModeRepositoryProvider);
  return StartShoppingSessionUseCase(repository);
});

final endShoppingSessionUseCaseProvider =
    Provider<EndShoppingSessionUseCase>((ref) {
  final repository = ref.watch(shoppingModeRepositoryProvider);
  return EndShoppingSessionUseCase(repository);
});

final getActiveSessionUseCaseProvider =
    Provider<GetActiveSessionUseCase>((ref) {
  final repository = ref.watch(shoppingModeRepositoryProvider);
  return GetActiveSessionUseCase(repository);
});

final activeSessionProvider = FutureProvider.family<
    ShoppingModeSessionModel?,
    ({String userId, String listId})>((ref, params) async {
  final useCase = ref.watch(getActiveSessionUseCaseProvider);
  return useCase.call(
    userId: params.userId,
    listId: params.listId,
  );
});
