import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/supabase_notification_repository.dart';
import '../../domain/entities/notification_preference.dart';
import '../../domain/usecases/get_notification_preferences_usecase.dart';
import '../../domain/usecases/update_notification_preferences_usecase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return SupabaseNotificationRepository(Supabase.instance.client);
});

final getNotificationPreferencesUseCaseProvider =
    Provider<GetNotificationPreferencesUseCase>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return GetNotificationPreferencesUseCase(repository);
});

final updateNotificationPreferencesUseCaseProvider =
    Provider<UpdateNotificationPreferencesUseCase>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return UpdateNotificationPreferencesUseCase(repository);
});

final notificationPreferencesProvider =
    AsyncNotifierProvider<NotificationPreferencesNotifier, List<NotificationPreference>>(
  NotificationPreferencesNotifier.new,
);

class NotificationPreferencesNotifier
    extends AsyncNotifier<List<NotificationPreference>> {
  @override
  Future<List<NotificationPreference>> build() async {
    final useCase = ref.read(getNotificationPreferencesUseCaseProvider);
    return await useCase.call();
  }

  Future<void> updatePreference(String category, bool enabled) async {
    final useCase = ref.read(updateNotificationPreferencesUseCaseProvider);
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      return await useCase.call(preferences: [
        {'category': category, 'enabled': enabled},
      ]);
    });
  }

  Future<void> updateAllPreferences(List<Map<String, dynamic>> preferences) async {
    final useCase = ref.read(updateNotificationPreferencesUseCaseProvider);
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      return await useCase.call(preferences: preferences);
    });
  }
}
