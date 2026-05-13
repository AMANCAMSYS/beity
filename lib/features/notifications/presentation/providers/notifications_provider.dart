import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/notification.dart';
import '../../domain/usecases/get_notification_history_usecase.dart';
import '../../domain/usecases/mark_notifications_read_usecase.dart';
import 'notification_preferences_provider.dart';

final getNotificationHistoryUseCaseProvider =
    Provider<GetNotificationHistoryUseCase>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return GetNotificationHistoryUseCase(repository);
});

final markNotificationsReadUseCaseProvider =
    Provider<MarkNotificationsReadUseCase>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return MarkNotificationsReadUseCase(repository);
});

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<AppNotification>>(
  NotificationsNotifier.new,
);

class NotificationsNotifier extends AsyncNotifier<List<AppNotification>> {
  int _offset = 0;
  final int _limit = 20;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  @override
  Future<List<AppNotification>> build() async {
    _offset = 0;
    _hasMore = true;
    final useCase = ref.read(getNotificationHistoryUseCaseProvider);
    final notifications = await useCase.call(limit: _limit, offset: 0);
    _offset = notifications.length;
    _hasMore = notifications.length == _limit;
    return notifications;
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore) return;

    _isLoadingMore = true;
    ref.notifyListeners();

    try {
      final useCase = ref.read(getNotificationHistoryUseCaseProvider);
      final moreNotifications = await useCase.call(
        limit: _limit,
        offset: _offset,
      );

      final current = state.valueOrNull ?? [];
      state = AsyncValue.data([...current, ...moreNotifications]);

      _offset += moreNotifications.length;
      _hasMore = moreNotifications.length == _limit;
    } finally {
      _isLoadingMore = false;
      ref.notifyListeners();
    }
  }

  Future<void> markAsRead(List<String> notificationIds) async {
    final useCase = ref.read(markNotificationsReadUseCaseProvider);
    await useCase.call(notificationIds);

    // Update local state
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(
      current.map((n) {
        if (notificationIds.contains(n.id)) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList(),
    );
  }

  Future<void> markAllAsRead() async {
    final repository = ref.read(notificationRepositoryProvider);
    await repository.markAllAsRead();

    // Update local state
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(
      current.map((n) => n.copyWith(isRead: true)).toList(),
    );
  }
}
