import '../../domain/entities/notification.dart';
import '../../data/repositories/notification_repository.dart';

class GetNotificationHistoryUseCase {
  final NotificationRepository _repository;

  GetNotificationHistoryUseCase(this._repository);

  Future<List<AppNotification>> call({
    int limit = 20,
    int offset = 0,
    String? homeId,
    String? category,
    bool unreadOnly = false,
  }) async {
    return await _repository.getNotificationHistory(
      limit: limit,
      offset: offset,
      homeId: homeId,
      category: category,
      unreadOnly: unreadOnly,
    );
  }
}
