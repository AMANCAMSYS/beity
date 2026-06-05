import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sawa/core/services/supabase_service.dart';
import '../../data/repositories/shopping_mode_repository.dart';
import '../../data/repositories/supabase_shopping_mode_repository.dart';
import '../../domain/usecases/start_shopping_session_usecase.dart';
import '../../domain/usecases/end_shopping_session_usecase.dart';

final shoppingModeRepositoryProvider = Provider<ShoppingModeRepository>((ref) {
  final client = SupabaseService.client;
  return SupabaseShoppingModeRepository(client);
});

final startShoppingSessionUseCaseProvider =
    Provider<StartShoppingSessionUseCase>((ref) {
      final repository = ref.watch(shoppingModeRepositoryProvider);
      return StartShoppingSessionUseCase(repository);
    });

final endShoppingSessionUseCaseProvider = Provider<EndShoppingSessionUseCase>((
  ref,
) {
  final repository = ref.watch(shoppingModeRepositoryProvider);
  return EndShoppingSessionUseCase(repository);
});
