import '../../domain/entities/notification_preference.dart';
import '../../data/repositories/notification_repository.dart';

class UpdateNotificationPreferencesUseCase {
  final NotificationRepository _repository;

  UpdateNotificationPreferencesUseCase(this._repository);

  Future<List<NotificationPreference>> call({
    required List<Map<String, dynamic>> preferences,
  }) async {
    return await _repository.updatePreferences(preferences: preferences);
  }
}
