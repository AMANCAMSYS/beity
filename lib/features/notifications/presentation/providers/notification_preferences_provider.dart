import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beity/core/services/supabase_service.dart';

import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/supabase_notification_repository.dart';
import '../../domain/entities/notification_preference.dart';
import '../../domain/usecases/get_notification_preferences_usecase.dart';
import '../../domain/usecases/update_notification_preferences_usecase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../homes/presentation/providers/homes_provider.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return SupabaseNotificationRepository(SupabaseService.client);
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
    AsyncNotifierProvider<NotificationPreferencesNotifier, NotificationPreferences>(
  NotificationPreferencesNotifier.new,
);

class NotificationPreferencesNotifier
    extends AsyncNotifier<NotificationPreferences> {
  @override
  Future<NotificationPreferences> build() async {
    final homeId = ref.watch(activeHomeIdProvider).valueOrNull;
    if (homeId == null || homeId.isEmpty) {
      throw Exception('لا يوجد منزل نشط');
    }

    final useCase = ref.read(getNotificationPreferencesUseCaseProvider);
    return useCase.call(homeId: homeId);
  }

  Future<void> updateField(String field, bool value) async {
    final homeId = ref.read(activeHomeIdProvider).valueOrNull;
    if (homeId == null) return;

    final useCase = ref.read(updateNotificationPreferencesUseCaseProvider);
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      return useCase.call(homeId: homeId, field: field, value: value);
    });
  }
}
