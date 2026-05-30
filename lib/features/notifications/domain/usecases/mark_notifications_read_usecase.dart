import '../../data/repositories/notification_repository.dart';

class MarkNotificationsReadUseCase {
  final NotificationRepository _repository;

  MarkNotificationsReadUseCase(this._repository);

  Future<int> call(List<String> notificationIds) async {
    return _repository.markAsRead(notificationIds);
  }
}
