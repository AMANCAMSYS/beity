import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/get_unread_count_usecase.dart';
import 'notification_preferences_provider.dart';

final getUnreadCountUseCaseProvider = Provider<GetUnreadCountUseCase>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return GetUnreadCountUseCase(repository);
});

final unreadCountProvider = AsyncNotifierProvider<UnreadCountNotifier, int>(
  UnreadCountNotifier.new,
);

class UnreadCountNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    final useCase = ref.read(getUnreadCountUseCaseProvider);
    return useCase.call();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final useCase = ref.read(getUnreadCountUseCaseProvider);
      return useCase.call();
    });
  }

  void decrement(int count) {
    final current = state.valueOrNull ?? 0;
    state = AsyncValue.data((current - count).clamp(0, current));
  }

  void reset() {
    state = const AsyncValue.data(0);
  }
}
