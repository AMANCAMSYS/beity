import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sawa/core/services/supabase_service.dart';

import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/local_first_notification_repository.dart';
import '../../domain/entities/notification_preference.dart';
import '../../domain/usecases/get_notification_preferences_usecase.dart';
import '../../domain/usecases/update_notification_preferences_usecase.dart';
import '../../../homes/presentation/providers/homes_provider.dart';
import '../../../offline_queue/presentation/providers/offline_queue_provider.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final queueDataSource = ref.read(queueDataSourceProvider);
  return LocalFirstNotificationRepository(
    client: SupabaseService.client,
    queueDataSource: queueDataSource,
  );
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
    AsyncNotifierProvider<
      NotificationPreferencesNotifier,
      NotificationPreferences
    >(NotificationPreferencesNotifier.new);

class NotificationPreferencesNotifier
    extends AsyncNotifier<NotificationPreferences> {
  @override
  Future<NotificationPreferences> build() async {
    final homeId = ref.watch(resolvedActiveHomeIdProvider);
    if (homeId == null || homeId.isEmpty) {
      throw Exception('no_active_home');
    }

    final useCase = ref.read(getNotificationPreferencesUseCaseProvider);
    try {
      return await useCase.call(homeId: homeId);
    } catch (e) {
      return NotificationPreferences(
        id: 'default',
        userId: SupabaseService.currentUser?.id ?? '',
        homeId: homeId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  Future<void> updateField(String field, bool value) async {
    final homeId = ref.read(resolvedActiveHomeIdProvider);
    if (homeId == null) return;

    final useCase = ref.read(updateNotificationPreferencesUseCaseProvider);
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      return useCase.call(homeId: homeId, field: field, value: value);
    });
  }
}
