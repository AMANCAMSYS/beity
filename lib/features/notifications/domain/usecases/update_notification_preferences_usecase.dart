import '../../domain/entities/notification_preference.dart';
import '../../data/repositories/notification_repository.dart';

class UpdateNotificationPreferencesUseCase {
  final NotificationRepository _repository;

  UpdateNotificationPreferencesUseCase(this._repository);

  Future<NotificationPreferences> call({
    required String homeId,
    required String field,
    required bool value,
  }) async {
    return _repository.updatePreference(
      homeId: homeId,
      field: field,
      value: value,
    );
  }
}
