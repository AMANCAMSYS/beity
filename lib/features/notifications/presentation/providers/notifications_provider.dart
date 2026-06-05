import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sawa/core/services/local_cache_notifier.dart';

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

enum NotificationFeedFilter { all, unread }

final notificationFeedFilterProvider = StateProvider<NotificationFeedFilter>(
  (ref) => NotificationFeedFilter.all,
);

class NotificationsNotifier extends AsyncNotifier<List<AppNotification>> {
  int _offset = 0;
  final int _limit = 20;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  Object? _loadMoreError;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  Object? get loadMoreError => _loadMoreError;

  @override
  Future<List<AppNotification>> build() async {
    final filter = ref.watch(notificationFeedFilterProvider);
    final subscription = LocalCacheNotifier.stream.listen((event) {
      if (event.entityType == 'notifications') {
        ref.invalidateSelf();
      }
    });
    ref.onDispose(subscription.cancel);

    _offset = 0;
    _hasMore = true;
    _isLoadingMore = false;
    _loadMoreError = null;
    final useCase = ref.read(getNotificationHistoryUseCaseProvider);
    final notifications = await useCase.call(
      limit: _limit,
      offset: 0,
      unreadOnly: filter == NotificationFeedFilter.unread,
    );
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
      final filter = ref.read(notificationFeedFilterProvider);
      final moreNotifications = await useCase.call(
        limit: _limit,
        offset: _offset,
        unreadOnly: filter == NotificationFeedFilter.unread,
      );

      final current = state.value ?? [];
      state = AsyncValue.data([...current, ...moreNotifications]);

      _offset += moreNotifications.length;
      _hasMore = moreNotifications.length == _limit;
      _loadMoreError = null;
    } catch (error) {
      _loadMoreError = error;
    } finally {
      _isLoadingMore = false;
      ref.notifyListeners();
    }
  }

  Future<void> markAsRead(List<String> notificationIds) async {
    final useCase = ref.read(markNotificationsReadUseCaseProvider);
    await useCase.call(notificationIds);

    // Update local state
    final current = state.value ?? [];
    final filter = ref.read(notificationFeedFilterProvider);
    if (filter == NotificationFeedFilter.unread) {
      state = AsyncValue.data(
        current.where((n) => !notificationIds.contains(n.id)).toList(),
      );
      return;
    }

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
    final current = state.value ?? [];
    final filter = ref.read(notificationFeedFilterProvider);
    state = AsyncValue.data(
      filter == NotificationFeedFilter.unread
          ? []
          : current.map((n) => n.copyWith(isRead: true)).toList(),
    );
  }
}
