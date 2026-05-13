import '../../domain/entities/notification_preference.dart';
import '../../data/repositories/notification_repository.dart';

class GetNotificationPreferencesUseCase {
  final NotificationRepository _repository;

  GetNotificationPreferencesUseCase(this._repository);

  Future<List<NotificationPreference>> call() async {
    return await _repository.getPreferences();
  }
}
