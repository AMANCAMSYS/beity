import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/features/notifications/data/repositories/notification_repository.dart';
import 'package:sawa/features/notifications/domain/entities/notification.dart';
import 'package:sawa/features/notifications/domain/entities/notification_preference.dart';
import 'package:sawa/features/notifications/presentation/providers/notification_preferences_provider.dart';
import 'package:sawa/features/notifications/presentation/providers/notifications_provider.dart';

void main() {
  test('notifications provider loads all notifications by default', () async {
    final repository = _FakeNotificationRepository([
      _notification(id: 'read', isRead: true),
      _notification(id: 'unread', isRead: false),
    ]);
    final container = ProviderContainer(
      overrides: [notificationRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final notifications = await container.read(notificationsProvider.future);

    expect(notifications, hasLength(2));
    expect(repository.historyRequests.single.unreadOnly, false);
  });

  test(
    'unread filter fetches unread notifications and removes read item locally',
    () async {
      final repository = _FakeNotificationRepository([
        _notification(id: 'read', isRead: true),
        _notification(id: 'unread', isRead: false),
      ]);
      final container = ProviderContainer(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      container.read(notificationFeedFilterProvider.notifier).state =
          NotificationFeedFilter.unread;

      final notifications = await container.read(notificationsProvider.future);
      expect(notifications.map((n) => n.id), ['unread']);
      expect(repository.historyRequests.single.unreadOnly, true);

      await container.read(notificationsProvider.notifier).markAsRead([
        'unread',
      ]);

      expect(container.read(notificationsProvider).value, isEmpty);
      expect(repository.markedReadIds, ['unread']);
    },
  );
}

AppNotification _notification({required String id, required bool isRead}) {
  return AppNotification(
    id: id,
    userId: 'user-1',
    homeId: 'home-1',
    category: 'shopping_list',
    type: 'item_added',
    title: 'Milk added',
    body: 'Milk was added to groceries',
    targetRoute: '/shopping-lists/list-1',
    isRead: isRead,
    createdAt: DateTime.utc(2026),
  );
}

class _HistoryRequest {
  final int limit;
  final int offset;
  final bool unreadOnly;

  const _HistoryRequest({
    required this.limit,
    required this.offset,
    required this.unreadOnly,
  });
}

class _FakeNotificationRepository implements NotificationRepository {
  final List<AppNotification> _notifications;
  final historyRequests = <_HistoryRequest>[];
  final markedReadIds = <String>[];

  _FakeNotificationRepository(this._notifications);

  @override
  Future<List<AppNotification>> getNotificationHistory({
    int limit = 20,
    int offset = 0,
    String? homeId,
    String? category,
    bool unreadOnly = false,
  }) async {
    historyRequests.add(
      _HistoryRequest(limit: limit, offset: offset, unreadOnly: unreadOnly),
    );
    final filtered = unreadOnly
        ? _notifications.where((notification) => !notification.isRead).toList()
        : _notifications;
    return filtered.skip(offset).take(limit).toList();
  }

  @override
  Future<int> markAsRead(List<String> notificationIds) async {
    markedReadIds.addAll(notificationIds);
    return notificationIds.length;
  }

  @override
  Future<int> getUnreadCount() async =>
      _notifications.where((n) => !n.isRead).length;

  @override
  Future<int> markAllAsRead() async => _notifications.length;

  @override
  Future<NotificationPreferences> getPreferences({required String homeId}) {
    throw UnimplementedError();
  }

  @override
  Future<NotificationPreferences> updatePreference({
    required String homeId,
    required String field,
    required bool value,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> sendNotification({
    required String eventType,
    required String homeId,
    required String actorId,
    required String referenceId,
    required String referenceType,
    Map<String, dynamic>? context,
  }) async {}
}
