import '../../data/repositories/notification_repository.dart';

class GetUnreadCountUseCase {
  final NotificationRepository _repository;

  GetUnreadCountUseCase(this._repository);

  Future<int> call() async {
    return _repository.getUnreadCount();
  }
}
